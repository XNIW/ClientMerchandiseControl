#!/usr/bin/env python3
"""Un simulatore iOS proprio, riusabile fra smoke e visual in step separati."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import signal
import stat
import subprocess
import tempfile
import time
import uuid

UUID = re.compile(r'^[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}$')
PREFIX = 'CMC-Task054-Owned-'
OWNER_CONTEXT = ('GITHUB_RUN_ID', 'GITHUB_RUN_ATTEMPT', 'GITHUB_JOB', 'GITHUB_SHA')
OWNED_ENVIRONMENT = 'owned-launchd-environment'
OWNED_DESCRIPTOR = 'owned-descriptor-launchd'
DESCRIPTOR_KIND = 'owned-descriptor-launchd.v1'
OWNED_DEVICE_TYPE = 'com.apple.CoreSimulator.SimDeviceType.iPhone-17'
READINESS_BUDGET = 30
READINESS_KIND = 'owned-launchd-environment.v1'
SMOKE = ['flutter', 'test', 'integration_test/app_shell_smoke_test.dart',
         '--no-pub', '--reporter', 'expanded', '--verbose']


class Failure(Exception):
    def __init__(self, code, reason, output=''):
        super().__init__(reason)
        self.code, self.output = code, output


def owned_descriptor_observation(record, devices_root=None):
    """Metadata del solo UUID creato, non attestazione readiness o schema nativo."""
    device = record.get('device', '')
    if (not isinstance(device, str) or not UUID.fullmatch(device) or
            record.get('creationStarted') is not True or
            record.get('bootstatusCompleted') is not True or
            record.get('cleanup') != 'NOT_RUN' or
            record.get('processCleanupFailed') or
            record.get('ownerContext') != {key: os.environ.get(key) for key in OWNER_CONTEXT} or
            not re.fullmatch(r'[0-9a-f]{32}', record.get('nonce', '')) or
            record.get('name') != PREFIX + record['nonce']):
        raise Failure(2, 'descriptor observation senza ownership/bootstatus')
    # Parametro interno solo per test filesystem sintetici; CLI senza override.
    base = Path(devices_root) if devices_root is not None else (
        Path.home() / 'Library/Developer/CoreSimulator/Devices')
    owner = os.geteuid()
    base_before = base.lstat()
    if not stat.S_ISDIR(base_before.st_mode) or base_before.st_uid != owner:
        raise Failure(2, 'directory descriptor non propria/regolare')
    fds = []
    try:
        # Openat ancorato a FD propri: O_NOFOLLOW sul solo file finale non
        # impedisce una sostituzione symlink della directory UUID intermedia.
        base_fd = os.open(base, os.O_RDONLY | os.O_NOFOLLOW | os.O_DIRECTORY)
        fds.append(base_fd)
        base_opened = os.fstat(base_fd)
        if (base_opened.st_dev, base_opened.st_ino, base_opened.st_uid) != (
                base_before.st_dev, base_before.st_ino, owner):
            raise Failure(2, 'directory base cambiata prima della lettura')
        device_before = os.stat(device, dir_fd=base_fd, follow_symlinks=False)
        if not stat.S_ISDIR(device_before.st_mode) or device_before.st_uid != owner:
            raise Failure(2, 'directory UUID non propria/regolare')
        device_fd = os.open(device, os.O_RDONLY | os.O_NOFOLLOW | os.O_DIRECTORY,
                            dir_fd=base_fd)
        fds.append(device_fd)
        device_opened = os.fstat(device_fd)
        if (device_opened.st_dev, device_opened.st_ino, device_opened.st_uid) != (
                device_before.st_dev, device_before.st_ino, owner):
            raise Failure(2, 'directory UUID cambiata prima della lettura')
        before = os.stat('device.plist', dir_fd=device_fd, follow_symlinks=False)
        if not stat.S_ISREG(before.st_mode) or before.st_uid != owner or before.st_size > 65536:
            raise Failure(2, 'descriptor non proprio/regolare/bounded')
        # O_NONBLOCK evita attese su FIFO/device sostituiti tra stat e open;
        # fstat sotto mantiene accettabile soltanto il file regolare bounded.
        descriptor = os.open('device.plist', os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
                             dir_fd=device_fd)
        fds.append(descriptor)
        opened = os.fstat(descriptor)
        if (not stat.S_ISREG(opened.st_mode) or opened.st_size > 65536 or
                (opened.st_dev, opened.st_ino, opened.st_uid) != (
                    before.st_dev, before.st_ino, owner)):
            raise Failure(2, 'descriptor sostituito prima della lettura')
        data = os.read(descriptor, 65537)
        if len(data) > 65536:
            raise Failure(2, 'descriptor oltre il limite')
        after = os.stat('device.plist', dir_fd=device_fd, follow_symlinks=False)
        device_after = os.stat(device, dir_fd=base_fd, follow_symlinks=False)
        base_after = base.lstat()
        if (not stat.S_ISDIR(base_after.st_mode) or
                not stat.S_ISDIR(device_after.st_mode) or
                not stat.S_ISREG(after.st_mode) or
                (base_after.st_dev, base_after.st_ino, base_after.st_uid) != (
                    base_opened.st_dev, base_opened.st_ino, owner) or
                (device_after.st_dev, device_after.st_ino, device_after.st_uid) != (
                    device_opened.st_dev, device_opened.st_ino, owner) or
                (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns) != (
                    opened.st_dev, opened.st_ino, opened.st_size, opened.st_mtime_ns)):
            raise Failure(2, 'descriptor/namespace cambiato durante la lettura')
    finally:
        for descriptor in reversed(fds):
            os.close(descriptor)
    try:
        payload = plistlib.loads(data)
    except Failure:
        raise
    except Exception:
        # ExpatError XML e gli altri errori parser non sono tutti ValueError.
        # Normalizzare in Failure mantiene il cleanup del UUID già creato.
        raise Failure(2, 'descriptor plist non decodificabile') from None
    if not isinstance(payload, dict) or len(payload) > 128 or any(
            not isinstance(key, str) or not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]{0,63}', key)
            for key in payload):
        raise Failure(2, 'schema descriptor non bounded/oggetto')
    selected = {}
    expected = {'UDID': device, 'name': record['name'], 'runtime': record.get('runtime')}
    for key in ('UDID', 'name', 'runtime', 'deviceType', 'deviceTypeIdentifier', 'state'):
        field = {'present': key in payload}
        if key in payload:
            value = payload[key]
            field['type'] = type(value).__name__
            if key in expected:
                field['matchesExpected'] = value == expected[key]
            if (key == 'UDID' and isinstance(value, str) and value == device or
                    key == 'name' and isinstance(value, str) and value == record['name'] or
                    key in ('runtime', 'deviceType', 'deviceTypeIdentifier') and
                    isinstance(value, str) and re.fullmatch(
                        r'com\.apple\.CoreSimulator\.Sim(?:Runtime|DeviceType)\.[A-Za-z0-9._-]{1,100}', value) or
                    key == 'state' and type(value) is int and 0 <= value <= 16 or
                    key == 'state' and value in ('Booted', 'Shutdown', 'Booting', 'Creating')):
                field['value'] = value
        selected[key] = field
    return {
        'kind': 'owned-device-descriptor-observation.v1',
        'descriptorRead': 'PASS', 'readiness': 'NOT_RUN', 'nativeApp': 'NOT_RUN',
        'fileBytes': len(data), 'fileSha256': hashlib.sha256(data).hexdigest(),
        'fileOwnerMatches': True, 'fileIdentityStable': True, 'symlinkRejected': True,
        'topLevelKeys': sorted(payload), 'fields': selected,
    }


def validate_descriptor_readback(observation, record):
    """Solo campi stringa confermati dalla cattura propria, mai state==3."""
    if (not isinstance(observation, dict) or
            observation.get('kind') != 'owned-device-descriptor-observation.v1' or
            observation.get('descriptorRead') != 'PASS' or
            any(observation.get(key) is not True for key in (
                'fileOwnerMatches', 'fileIdentityStable', 'symlinkRejected')) or
            type(observation.get('fileBytes')) is not int or
            not 0 < observation['fileBytes'] <= 65536 or
            not isinstance(observation.get('fileSha256'), str) or not re.fullmatch(
                r'[0-9a-f]{64}', observation['fileSha256'])):
        raise Failure(2, 'descriptor readback non qualificato')
    expected = {'UDID': record['device'], 'name': record['name'],
                'runtime': record['runtime'], 'deviceType': record['deviceType']}
    fields = observation.get('fields', {})
    if not isinstance(fields, dict):
        raise Failure(2, 'descriptor fields non qualificati')
    for key, wanted in expected.items():
        field = fields.get(key, {})
        if (not isinstance(wanted, str) or not isinstance(field, dict) or
                field.get('present') is not True or not isinstance(field.get('value'), str) or
                field.get('type') != 'str' or field.get('value') != wanted or
                key != 'deviceType' and field.get('matchesExpected') is not True):
            raise Failure(2, 'descriptor non coincide con ownership/runtime/type')


def descriptor_attestation(before, after):
    return {
        'kind': DESCRIPTOR_KIND, 'bootstatusExitCode': 0,
        'udidMatches': True, 'nameMatches': True, 'runtimeMatches': True,
        'deviceTypeMatches': True, 'descriptorReadbacksQualified': True,
        'descriptorBeforeSha256': before['fileSha256'],
        'descriptorAfterSha256': after['fileSha256'],
        'spawnExecutable': '/usr/bin/true', 'spawnStandalone': False,
        'spawnExitCode': 0, 'commandBudgetSeconds': READINESS_BUDGET,
        'globalPostBootInventory': 'NOT_RUN',
    }


def process_diagnostic(operation, error=None, **metadata):
    # Mai str(error), cmd, stdout, stderr o nomi/argomenti di processi altrui.
    detail = dict(operation=operation, **metadata)
    if error is not None:
        detail['errorType'] = type(error).__name__
        if isinstance(error, subprocess.TimeoutExpired):
            detail['timeoutSeconds'] = error.timeout
        elif isinstance(error, OSError):
            detail['errno'] = error.errno
        elif isinstance(error, Failure):
            detail['failureCode'] = error.code
    print('DIAGNOSTIC: ' + json.dumps(detail, sort_keys=True), flush=True)


def group_has_live_members(group):
    if type(group) is not int or group <= 0:
        process_diagnostic('kernelGroupProbe', reason='invalidOwnedPgid',
                           numericPgid=type(group) is int)
        raise Failure(1, 'process-group proprio invalido')
    try:
        os.killpg(group, 0)  # Esistenza/permessi, senza inviare un segnale.
    except ProcessLookupError:
        return False
    except PermissionError as error:
        # EPERM non prova assenza: anche un gruppo proprio zombie può darlo.
        # La probe ps originale resta decisiva e fallisce in modo chiuso.
        process_diagnostic('kernelGroupProbe', error, ownedPgid=group)
    except OSError as error:
        process_diagnostic('kernelGroupProbe', error, ownedPgid=group)
        raise
    # Solo metadati pgid/stato, mai argomenti o dati applicativi.
    try:
        result = subprocess.run(['ps', '-axo', 'pgid=,stat='], capture_output=True,
                                text=True, timeout=2, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        process_diagnostic('psProbe', error, ownedPgid=group)
        raise
    if result.returncode:
        process_diagnostic('psProbe', ownedPgid=group, reason='exitStatus',
                           exitCode=result.returncode, rowCount=len(result.stdout.splitlines()))
        raise Failure(1, 'process-group probe fallita')
    alive = False
    rows = result.stdout.splitlines()
    for line in rows:
        fields = line.split()
        if len(fields) != 2 or not fields[0].isdigit():
            process_diagnostic('psProbe', ownedPgid=group, reason='shape',
                               rowCount=len(rows), fieldCount=len(fields),
                               numericPgid=bool(fields and fields[0].isdigit()))
            raise Failure(1, 'process-group probe non verificabile')
        if int(fields[0]) == group and not fields[1].startswith('Z'):
            alive = True
    return alive


def stop_owned_process(process):
    """Il leader terminato non dimostra che i discendenti siano terminati."""
    probe_error = None
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            pass
        deadline = time.monotonic() + 5
        while True:
            try:
                if not group_has_live_members(process.pid):
                    process.wait(timeout=2)
                    if probe_error:
                        raise probe_error
                    return
            except (OSError, subprocess.TimeoutExpired, Failure) as error:
                probe_error = error
                break  # Il KILL del solo gruppo proprio viene comunque tentato.
            if time.monotonic() >= deadline:
                break
            time.sleep(0.05)
    if probe_error:
        raise probe_error
    process_diagnostic('ownedGroupVerification', ownedPgid=process.pid,
                       reason='liveMembersAfterKill')
    raise Failure(1, 'process-group proprio ancora attivo dopo cleanup bounded')


class IosOwnedRunner:
    def __init__(self, receipt=None):
        self.receipt = Path(receipt) if receipt else None
        self.record = None
        self.owns_receipt = False
        self.phase = 'initial'
        self.pending_signal = None
        self.process_cleanup_signal = None
        self.process_cleanup_failed = False
        self.observed_device_state = None

    def interrupted(self, signum, _frame):
        if self.phase == 'process_cleanup':
            if self.process_cleanup_signal is None:
                self.process_cleanup_signal = signum
            return  # Quiescenza bounded prima di riproporre il primo segnale.
        if self.phase == 'create':
            # Create bounded30: acquisire UUID prima di reagire consente cleanup
            # quando TERM arriva tra la creazione e la risposta del provider.
            if self.pending_signal is None:
                self.pending_signal = signum
            return
        raise Failure(128 + signum, 'interrotto')

    def command(self, arguments, timeout, capture=False):
        print('+ ' + ' '.join(arguments), flush=True)
        process = subprocess.Popen(arguments, start_new_session=True,
                                   stdout=subprocess.PIPE if capture else None,
                                   text=True)
        primary, output = None, ''
        try:
            output, _ = process.communicate(timeout=timeout)
            output = output or ''
            if process.returncode:
                primary = Failure(process.returncode if process.returncode > 0
                                  else 128 - process.returncode,
                                  'comando fallito', output)
        except subprocess.TimeoutExpired as error:
            captured = error.output or ''
            output = captured.decode() if isinstance(captured, bytes) else captured
            primary = Failure(124, f'timeout dopo {timeout}s', output)
        except BaseException as error:
            primary = error
        finally:
            previous_phase = self.phase
            self.phase = 'process_cleanup'
            self.process_cleanup_signal = None
            try:
                must_stop = primary is not None
                if not must_stop:
                    try:
                        must_stop = group_has_live_members(process.pid)
                    except (OSError, subprocess.TimeoutExpired, Failure) as error:
                        process_diagnostic('commandProbe', error, ownedPgid=process.pid)
                        self.process_cleanup_failed = True
                        must_stop = True
                        primary = Failure(1, 'probe processi non verificata', output)
                try:
                    # Anche successo del leader con figli rimasti va verificato.
                    if must_stop:
                        stop_owned_process(process)
                except (OSError, subprocess.TimeoutExpired, Failure) as error:
                    process_diagnostic('commandCleanup', error, ownedPgid=process.pid)
                    self.process_cleanup_failed = True
                    print('FAIL: cleanup del gruppo proprio non verificato', flush=True)
                    if primary is None:
                        primary = Failure(1, 'cleanup processi fallito', output)
            finally:
                self.phase = previous_phase
            if primary is None and self.process_cleanup_signal is not None:
                primary = Failure(128 + self.process_cleanup_signal,
                                  'interrotto durante cleanup processi', output)
        if primary is not None:
            raise primary
        return output

    def persist(self, exclusive=False):
        self.record['processCleanupFailed'] = bool(
            self.process_cleanup_failed or self.record.get('processCleanupFailed'))
        encoded = json.dumps(self.record, indent=2) + '\n'
        if exclusive:
            with os.fdopen(os.open(self.receipt, os.O_WRONLY | os.O_CREAT | os.O_EXCL,
                                   0o600), 'w') as output:
                output.write(encoded)
            self.owns_receipt = True
            return
        with tempfile.NamedTemporaryFile(mode='w', dir=self.receipt.parent,
                                         delete=False) as output:
            temporary = Path(output.name)
            output.write(encoded)
        try:
            os.replace(temporary, self.receipt)
        finally:
            temporary.unlink(missing_ok=True)

    def device_record(self, device):
        payload = json.loads(self.command(
            ['xcrun', 'simctl', 'list', 'devices', '--json'], 30, capture=True))
        found = [(entry, runtime) for runtime, entries in payload['devices'].items()
                 for entry in entries if entry.get('udid', '').lower() == device.lower()]
        if len(found) > 1:
            raise Failure(2, 'identità simulatore ambigua')
        return found[0] if found else (None, None)

    def check_owned_environment(self, device):
        record = self.record
        if (record is None or
                device.lower() != str(record.get('device')).lower() or
                record.get('readinessMethod') != OWNED_ENVIRONMENT or
                record.get('bootstatusCompleted') is not True or
                record.get('cleanup') != 'NOT_RUN' or
                record.get('processCleanupFailed')):
            raise Failure(2, 'readiness per-device priva di ownership/bootstatus attuale')
        runtime_version = record.get('runtimeVersion')
        if (not isinstance(runtime_version, str) or not re.fullmatch(
                r'26\.[0-9]+(?:\.[0-9]+)?', runtime_version) or
                record.get('runtime') != 'com.apple.CoreSimulator.SimRuntime.iOS-' +
                runtime_version.replace('.', '-') or
                record.get('name') != PREFIX + record.get('nonce', '')):
            raise Failure(2, 'identità runtime/name per-device invalida')
        expected = (
            ('SIMULATOR_UDID', device),
            ('SIMULATOR_DEVICE_NAME', record['name']),
            ('SIMULATOR_RUNTIME_VERSION', runtime_version),
        )
        # Un budget totale equivalente all'inventory precedente, mai 3x30s.
        # Spawn senza --standalone richiede il launchd del device Booted: il
        # semplice simctl getenv consente anche Booting e qui non è sufficiente.
        deadline = time.monotonic() + READINESS_BUDGET
        for variable, wanted in expected:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise Failure(124, 'budget readiness per-device esaurito')
            observed = self.command(
                ['xcrun', 'simctl', 'spawn', device, 'launchctl', 'getenv', variable],
                min(READINESS_BUDGET, remaining), capture=True).strip()
            matches = (observed.lower() == wanted.lower()
                       if variable == 'SIMULATOR_UDID' else observed == wanted)
            if not matches:
                raise Failure(2, 'readiness per-device non coincide con ownership/runtime')
        self.observed_device_state = 'Booted'
        record['readinessAttestation'] = {
            'kind': READINESS_KIND, 'bootstatusExitCode': 0,
            'udidMatches': True, 'nameMatches': True, 'runtimeVersionMatches': True,
            'commandBudgetSeconds': READINESS_BUDGET,
            'globalPostBootInventory': 'NOT_RUN',
        }
        return True

    def check_owned_descriptor(self, device):
        record = self.record
        context = {key: os.environ.get(key) for key in OWNER_CONTEXT}
        if (record is None or not isinstance(record.get('device'), str) or
                device.lower() != record['device'].lower() or
                record.get('readinessMethod') != OWNED_DESCRIPTOR or
                record.get('creationStarted') is not True or
                record.get('bootstatusCompleted') is not True or
                record.get('cleanup') != 'NOT_RUN' or
                record.get('processCleanupFailed') or self.process_cleanup_failed or
                record.get('ownerContext') != context or
                any(not isinstance(value, str) or not value for value in context.values()) or
                not re.fullmatch(r'[0-9a-f]{32}', record.get('nonce', '')) or
                record.get('name') != PREFIX + record['nonce'] or
                record.get('deviceType') != OWNED_DEVICE_TYPE or
                not isinstance(record.get('runtime'), str) or not re.fullmatch(
                    r'com\.apple\.CoreSimulator\.SimRuntime\.iOS-26-[0-9]+(?:-[0-9]+)?',
                    record['runtime'])):
            raise Failure(2, 'descriptor readiness senza ownership/bootstatus attuale')
        observation = record.get('ownedDescriptorObservation')
        if ('ownedDescriptorObservation' in record and
                (not isinstance(observation, dict) or observation.get('descriptorRead') != 'PASS')):
            raise Failure(2, 'osservazione descriptor fallita: nessuna promozione')
        was_ready = record.get('ready') is True
        record['ready'] = False
        record.pop('readinessAttestation', None)
        record.pop('descriptorReadback', None)
        self.persist()  # Nessuna proof durevole precedente copre questo recheck.
        deadline = time.monotonic() + READINESS_BUDGET

        def remaining_budget():
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise Failure(124, 'budget descriptor readiness esaurito')
            return min(READINESS_BUDGET, remaining)

        remaining_budget()
        before = owned_descriptor_observation(record)
        validate_descriptor_readback(before, record)
        # Spawn normale passa dal launchd del UUID proprio e richiede Booted;
        # lo stato numerico del plist non viene interpretato come readiness.
        self.command(['xcrun', 'simctl', 'spawn', record['device'], '/usr/bin/true'],
                     remaining_budget(), capture=True)
        remaining_budget()
        after = owned_descriptor_observation(record)
        validate_descriptor_readback(after, record)
        remaining_budget()
        # Ogni lettura ha il proprio pin FD/path/owner; CoreSimulator può
        # riscrivere atomicamente il plist fra le letture mantenendo la stessa
        # identità semantica. I due hash restano evidence separate, non equality.
        if (record.get('ownerContext') != {key: os.environ.get(key) for key in OWNER_CONTEXT} or
                record.get('cleanup') != 'NOT_RUN' or record.get('processCleanupFailed') or
                self.process_cleanup_failed):
            raise Failure(2, 'identità/context descriptor cambiati durante readiness')
        record['descriptorReadback'] = {'before': before, 'after': after}
        record['readinessAttestation'] = descriptor_attestation(before, after)
        record['ready'] = was_ready
        self.observed_device_state = 'Booted'
        self.persist()
        return True

    def check_device(self, device, ready=False, owned=False):
        if not UUID.fullmatch(device):
            raise Failure(2, 'UUID simulatore invalido')
        if ready and owned and self.record is not None and \
                self.record.get('readinessMethod') == OWNED_ENVIRONMENT:
            return self.check_owned_environment(device)
        if ready and owned and self.record is not None and \
                self.record.get('readinessMethod') == OWNED_DESCRIPTOR:
            return self.check_owned_descriptor(device)
        entry, runtime = self.device_record(device)
        self.observed_device_state = entry.get('state') if entry else None
        if entry is None:
            if ready:
                raise Failure(2, 'simulatore richiesto assente')
            return False
        if owned and (entry.get('name') != self.record['name'] or
                      runtime != self.record['runtime']):
            raise Failure(2, 'ownership simulatore non coincide: nessuna mutazione')
        if ready and (not entry.get('isAvailable') or entry.get('state') != 'Booted'):
            raise Failure(2, 'simulatore richiesto non Booted/disponibile')
        return True

    def prepare(self, headless=False, readiness_attestation='inventory', observe_descriptor=False):
        self.record = {'schemaVersion': 1, 'nonce': uuid.uuid4().hex,
                       'device': None, 'creationStarted': False, 'cleanup': 'NOT_RUN'}
        if readiness_attestation not in ('inventory', OWNED_ENVIRONMENT, OWNED_DESCRIPTOR):
            raise Failure(2, 'metodo readiness non autorizzato')
        if readiness_attestation != 'inventory':
            self.record['readinessMethod'] = readiness_attestation
        if readiness_attestation == OWNED_DESCRIPTOR:
            self.record['deviceType'] = OWNED_DEVICE_TYPE
        self.record['ownerContext'] = {key: os.environ.get(key) for key in OWNER_CONTEXT}
        self.record['name'] = PREFIX + self.record['nonce']
        if headless:
            self.record['launchMode'] = 'headless'
        self.persist(exclusive=True)  # Nessuna creazione se la receipt esiste.
        developer = os.environ.get('DEVELOPER_DIR') or self.command(
            ['xcode-select', '-p'], 15, capture=True).strip()
        simulator = developer + '/Applications/Simulator.app'
        if not headless and not Path(simulator).is_dir():
            raise Failure(2, 'Simulator.app assente nella toolchain selezionata')
        payload = json.loads(self.command(['xcrun', 'simctl', 'list', 'runtimes',
                                          '--json'], 30, capture=True))
        available = [runtime for runtime in payload['runtimes']
                     if runtime.get('isAvailable') and runtime['identifier'].startswith(
                         'com.apple.CoreSimulator.SimRuntime.iOS-26-')]
        if not available:
            raise Failure(2, 'runtime iOS26 compatibile assente')
        runtime = max(available, key=lambda row: tuple(map(int, row['version'].split('.'))))
        self.record['runtime'] = runtime['identifier']
        if readiness_attestation != 'inventory':
            self.record['runtimeVersion'] = runtime['version']
        self.record['creationStarted'] = True
        self.persist()
        self.phase = 'create'
        creation_failure, device = None, ''
        try:
            device = self.command(['xcrun', 'simctl', 'create', self.record['name'],
                                  'com.apple.CoreSimulator.SimDeviceType.iPhone-17',
                                  self.record['runtime']], 30, capture=True).strip()
        except Failure as error:
            creation_failure, device = error, error.output.strip()
        self.phase = 'prepare'
        if UUID.fullmatch(device):
            self.record['device'] = device
            self.persist()  # Ownership durevole prima di boot/open.
        if self.pending_signal:
            raise Failure(128 + self.pending_signal, 'interrotto durante create')
        if creation_failure:
            raise creation_failure
        if not self.record['device']:
            raise Failure(2, 'create non ha restituito un UUID verificabile')
        self.check_device(device, owned=True)
        self.command(['xcrun', 'simctl', 'boot', device], 60)
        if not headless:
            self.command(['open', '-a', simulator, '--args', '-CurrentDeviceUDID', device], 60)
        self.command(['xcrun', 'simctl', 'bootstatus', device, '-b'], 300)
        if readiness_attestation != 'inventory' or observe_descriptor:
            self.record['bootstatusCompleted'] = True
            self.persist()
        if observe_descriptor:
            try:
                self.record['ownedDescriptorObservation'] = owned_descriptor_observation(self.record)
            except (Failure, OSError, ValueError) as error:
                if isinstance(error, Failure) and error.code >= 128:
                    raise
                self.record['ownedDescriptorObservation'] = {
                    'kind': 'owned-device-descriptor-observation.v1',
                    'descriptorRead': 'FAIL', 'readiness': 'NOT_RUN', 'nativeApp': 'NOT_RUN',
                    'errorType': type(error).__name__,
                }
            self.persist()
        self.check_device(device, ready=True, owned=True)
        self.record['ready'] = True
        self.persist()
        return device

    def load(self):
        metadata = self.receipt.lstat()
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.geteuid() or \
                metadata.st_mode & 0o077:
            raise Failure(2, 'receipt ownership non privata/regolare')
        record = json.loads(self.receipt.read_text())
        if record.get('schemaVersion') != 1 or not re.fullmatch(
                r'[0-9a-f]{32}', record.get('nonce', '')) or \
                record.get('name') != PREFIX + record['nonce']:
            raise Failure(2, 'receipt ownership invalida')
        if record.get('ownerContext') != {key: os.environ.get(key) for key in OWNER_CONTEXT}:
            raise Failure(2, 'receipt di altra run/job/revisione: nessuna mutazione')
        method = record.get('readinessMethod')
        if method is not None and method not in (OWNED_ENVIRONMENT, OWNED_DESCRIPTOR):
            raise Failure(2, 'receipt metodo readiness invalido')
        if method == OWNED_ENVIRONMENT and record.get('ready'):
            expected = {
                'kind': READINESS_KIND, 'bootstatusExitCode': 0,
                'udidMatches': True, 'nameMatches': True, 'runtimeVersionMatches': True,
                'commandBudgetSeconds': READINESS_BUDGET,
                'globalPostBootInventory': 'NOT_RUN',
            }
            if record.get('bootstatusCompleted') is not True or \
                    record.get('readinessAttestation') != expected:
                raise Failure(2, 'receipt readiness per-device non attestata')
        if method == OWNED_DESCRIPTOR and record.get('ready'):
            readback = record.get('descriptorReadback')
            if (record.get('bootstatusCompleted') is not True or
                    record.get('creationStarted') is not True or
                    record.get('deviceType') != OWNED_DEVICE_TYPE or
                    not isinstance(readback, dict) or set(readback) != {'before', 'after'}):
                raise Failure(2, 'receipt descriptor readiness non attestata')
            validate_descriptor_readback(readback['before'], record)
            validate_descriptor_readback(readback['after'], record)
            expected = descriptor_attestation(readback['before'], readback['after'])
            actual = record.get('readinessAttestation')
            if (not isinstance(actual, dict) or actual != expected or
                    any(type(actual.get(key)) is not type(value) for key, value in expected.items())):
                raise Failure(2, 'receipt descriptor attestazione invalida')
        self.record = record

    def cleanup(self):
        self.phase = 'cleanup'
        if not self.owns_receipt:
            self.load()
        # Solo receipt acquisita con O_EXCL o appena validata da load().
        attempts = self.record.setdefault('cleanupAttempts', [])
        if not isinstance(attempts, list):
            raise Failure(2, 'receipt tentativi cleanup invalida')
        incomplete = any(attempt.get('result') == 'NOT_RUN' for attempt in attempts)
        process_failed = bool(self.process_cleanup_failed or self.record.get('processCleanupFailed'))
        failed = process_failed or self.record.get('cleanup') == 'FAIL'
        attempt = {'attempt': len(attempts) + 1, 'result': 'NOT_RUN',
                   'resourceCleanup': 'NOT_RUN', 'processCleanupFailed': process_failed}
        attempts.append(attempt)
        if failed:
            self.record['cleanup'] = 'FAIL'
        self.persist()  # Flag durevole prima di inventory/readback che possono sollevare.
        primary = None
        try:
            resource_result = self.cleanup_device()
        except (Failure, OSError, ValueError, KeyError) as error:
            primary, resource_result = error, 'FAIL'
            attempt['errorType'] = type(error).__name__
        process_failed = bool(self.process_cleanup_failed or self.record.get('processCleanupFailed'))
        failed = failed or process_failed or resource_result == 'FAIL'
        self.record['cleanup'] = 'FAIL' if failed else 'BLOCKED' if incomplete else resource_result
        attempt.update(result=self.record['cleanup'], resourceCleanup=resource_result,
                       processCleanupFailed=process_failed)
        try:
            self.persist()
        except (OSError, ValueError, KeyError) as error:
            print(f'FAIL: persistenza cleanup ({type(error).__name__})', flush=True)
            if primary is None:
                primary = error
        if primary is not None:
            raise primary
        return self.record['cleanup'] == 'PASS'

    def cleanup_device(self):
        device = self.record.get('device')
        if not device:
            return 'BLOCKED' if self.record.get('creationStarted') else 'PASS'
        # Identità diversa impedisce sia shutdown sia delete.
        if not self.check_device(device, owned=True):
            return 'PASS'
        failed = False
        actions = ('delete',) if self.observed_device_state == 'Shutdown' else ('shutdown', 'delete')
        for action in actions:
            try:
                self.command(['xcrun', 'simctl', action, device], 30)
            except (OSError, Failure) as error:
                failed = True
                print(f'FAIL: cleanup {action} {type(error).__name__}', flush=True)
        if self.check_device(device, owned=True):
            failed = True
        return 'FAIL' if failed else 'PASS'

    def smoke(self, device):
        self.phase = 'smoke'
        primary = None
        try:
            if self.receipt is None:
                raise Failure(2, 'smoke --device richiede la receipt privata della run')
            if self.record is None:
                self.load()
            if not UUID.fullmatch(device) or device.lower() != str(
                    self.record.get('device')).lower():
                raise Failure(2, 'UUID smoke non coincide con la receipt: nessuna mutazione')
            if not self.record.get('ready') or self.record.get('cleanup') != 'NOT_RUN' or \
                    self.record.get('processCleanupFailed'):
                raise Failure(2, 'receipt smoke non pronta o cleanup precedente fallito')
            self.check_device(device, ready=True, owned=True)
            self.command(SMOKE + ['-d', device], 900)
        except (Failure, OSError, ValueError, KeyError) as error:
            primary = error
        finally:
            if self.record is not None and self.process_cleanup_failed:
                try:
                    self.persist()
                except (OSError, ValueError, KeyError) as error:
                    print(f'FAIL: persistenza cleanup processi ({type(error).__name__})', flush=True)
                    if primary is None:
                        primary = Failure(2, 'receipt cleanup processi non aggiornata')
        if primary is not None:
            raise primary


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    subcommands = parser.add_subparsers(dest='action', required=True)
    prepare = subcommands.add_parser('prepare')
    prepare.add_argument('--receipt', required=True)
    prepare.add_argument('--github-output')
    prepare.add_argument('--headless', action='store_true',
                         help='prepara il solo simulatore proprio via simctl, senza interfaccia GUI')
    prepare.add_argument('--readiness-attestation',
                         choices=('inventory', OWNED_ENVIRONMENT, OWNED_DESCRIPTOR), default='inventory',
                         help='opt-in per-device; inventory globale resta il comportamento storico')
    prepare.add_argument('--observe-owned-descriptor', action='store_true',
                         help='osserva solo metadata del UUID creato; non sostituisce readiness')
    cleanup = subcommands.add_parser('cleanup')
    cleanup.add_argument('--receipt', required=True)
    smoke = subcommands.add_parser('smoke')
    smoke.add_argument('--device')
    smoke.add_argument('--receipt', default=os.environ.get('CMC_IOS_OWNED_RECEIPT'))
    options = parser.parse_args(argv)
    standalone = options.action == 'smoke' and options.device is None
    receipt = getattr(options, 'receipt', None)
    if standalone:
        receipt = Path(tempfile.mkdtemp(prefix='cmc-ios-owned-')) / 'receipt.json'
    runner = IosOwnedRunner(receipt)
    for signum in (signal.SIGTERM, signal.SIGINT):
        signal.signal(signum, runner.interrupted)
    primary = 0
    must_cleanup = options.action == 'cleanup'
    try:
        if options.action == 'prepare' or standalone:
            device = runner.prepare(
                headless=getattr(options, 'headless', False),
                readiness_attestation=getattr(options, 'readiness_attestation', 'inventory'),
                observe_descriptor=getattr(options, 'observe_owned_descriptor', False))
            if options.action == 'prepare' and options.github_output:
                with open(options.github_output, 'a') as output:
                    output.write('device_id=' + device + '\n')
            if options.action == 'prepare':
                print('READY: simulatore proprio preparato per smoke e visual', flush=True)
        if options.action == 'smoke':
            runner.smoke(device if standalone else options.device)
    except (Failure, OSError, ValueError, KeyError) as error:
        primary = error.code if isinstance(error, Failure) else 2
        print(f'FAIL: {error}', flush=True)
        must_cleanup = must_cleanup or runner.owns_receipt
    finally:
        must_cleanup = must_cleanup or (standalone and runner.owns_receipt)
        if must_cleanup:
            # Non interrompere il cleanup proprio per un secondo TERM/INT.
            for signum in (signal.SIGTERM, signal.SIGINT):
                signal.signal(signum, signal.SIG_IGN)
            try:
                if not runner.cleanup() and primary == 0:
                    primary = 1
            except (Failure, OSError, ValueError, KeyError) as error:
                print(f'FAIL: cleanup non verificato ({type(error).__name__})', flush=True)
                if primary == 0:
                    primary = 1
    return primary


if __name__ == '__main__':
    raise SystemExit(main())

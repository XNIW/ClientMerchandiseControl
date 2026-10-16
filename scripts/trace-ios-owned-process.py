#!/usr/bin/env python3
"""Misure monotonic del trasporto esistente, senza nuovi timeout o segnali.

L'osservazione poll al timeout può effettuare il reap del leader già uscito;
questo limite è esplicito nella trace. Non stampa argv o output dei comandi.
"""
import contextlib
import datetime
import errno
import hashlib
import json
import os
import re
import selectors
import signal
from pathlib import Path
import subprocess
import time
import threading


def operation(arguments):
    if not isinstance(arguments, (list, tuple)):
        return 'subprocess'
    if arguments[:2] == ['xcrun', 'simctl'] and len(arguments) > 2:
        action = arguments[2]
        return 'simctl-' + action if action in (
            'help', 'list', 'create', 'boot', 'bootstatus', 'shutdown', 'delete',
            'listapps', 'install', 'launch', 'terminate', 'get_app_container') else 'simctl'
    return {'ps': 'ps-probe', 'open': 'simulator-open', 'xcode-select': 'developer-path',
            'flutter': 'flutter', 'git': 'revision', 'plutil': 'plist-conversion'}.get(
                arguments[0] if arguments else '', 'subprocess')


def output_metadata(output):
    if output is None:
        return {'bytes': 0, 'json': 'absent'}
    encoded = output.encode() if isinstance(output, str) else output
    result = {'bytes': len(encoded), 'sha256': hashlib.sha256(encoded).hexdigest()}
    try:
        json.loads(encoded)
        result['json'] = 'valid'
    except (ValueError, UnicodeError):
        result['json'] = 'invalid'
    return result


def owned_ps_metadata(output, groups):
    states = {group: [] for group in groups}
    for line in (output or '').splitlines():
        fields = line.split()
        if len(fields) != 2 or not fields[0].isdigit():
            return {'ps_shape': 'invalid', 'owned_groups': []}
        group = int(fields[0])
        if group in states:
            states[group].append(fields[1])
    return {'ps_shape': 'valid', 'owned_groups': [
        {'pgid': group, 'states': rows,
         'state': 'absent' if not rows else
             'zombie_only' if all(row.startswith('Z') for row in rows) else 'live'}
        for group, rows in sorted(states.items())]}


# Opt-in diagnostico del solo comando readiness, non una prova di readiness.
# sample sospende brevemente il target: il run strumentato non è una replica
# temporale neutra né un AB con run su altri worker/immagini.
class ReadinessObservation:
    CAP = 65536
    UUID = re.compile(r'^[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}$')

    def __init__(self, process, device, timeout, emit, popen):
        self.process, self.device, self.timeout = process, device, timeout
        self.emit, self.popen = emit, popen
        self.stop = threading.Event()
        self.started = datetime.datetime.now(datetime.timezone.utc)
        self.thread = threading.Thread(target=self.run, name='owned-readiness-observer')
        self.thread.daemon = False
        self.failure = None
        self.cleanup_error = None
        self.thread.start()

    def capture(self, arguments, seconds):
        """Un solo comando proprio, output bounded in RAM e reap anche su cancel."""
        if self.stop.is_set():
            return {'status': 'NOT_RUN', 'reason': 'gateCompleted'}, b'', b''
        child = self.popen(arguments, start_new_session=True, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
        result, output, errors = {'status': 'PASS'}, bytearray(), bytearray()
        deadline = time.monotonic() + seconds
        try:
            with selectors.DefaultSelector() as selected:
                selected.register(child.stdout, selectors.EVENT_READ, output)
                selected.register(child.stderr, selectors.EVENT_READ, errors)
                while selected.get_map():
                    if self.stop.is_set() or time.monotonic() >= deadline:
                        result = {'status': 'NOT_RUN' if self.stop.is_set() else 'BLOCKED',
                                  'reason': 'gateCompleted' if self.stop.is_set() else 'observerBudget'}
                        break
                    for key, _ in selected.select(min(.05, max(0, deadline - time.monotonic()))):
                        data = os.read(key.fileobj.fileno(), 4096)
                        if not data:
                            selected.unregister(key.fileobj)
                        elif len(output) + len(errors) + len(data) > self.CAP:
                            result = {'status': 'BLOCKED', 'reason': 'byteCap'}
                            break
                        else:
                            key.data.extend(data)
                    if result['status'] != 'PASS':
                        break
        finally:
            # Segnali solo al gruppo creato da questo observer, mai al target.
            # Anche un leader già terminato può avere discendenti nel gruppo.
            try:
                # EOF non equivale a processo gia uscito. Consentire l'exit
                # naturale bounded prima di segnalare un normale successo.
                if result['status'] == 'PASS':
                    try:
                        child.wait(timeout=.5)
                    except subprocess.TimeoutExpired:
                        pass
                if child.poll() is None:
                    try:
                        os.killpg(child.pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                    try:
                        child.wait(timeout=.25)
                    except subprocess.TimeoutExpired:
                        try:
                            os.killpg(child.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                        child.wait(timeout=.5)
                # Il leader reaped non prova assenza di figli nel suo gruppo.
                try:
                    os.killpg(child.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                child.wait(timeout=.5)
                # ps legge soltanto il gruppo osservativo proprio e solo stato.
                probe = self.popen(['/bin/ps', '-g', str(child.pid), '-o', 'pgid=,stat='],
                                   start_new_session=True, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
                try:
                    states, probe_errors = probe.communicate(timeout=.5)
                    fields = [line.split() for line in states.splitlines()]
                    if (len(states) > self.CAP or probe_errors or probe.returncode not in (0, 1) or any(
                            len(row) != 2 or not row[0].isdigit() or int(row[0]) != child.pid or
                            not row[1].startswith(b'Z') for row in fields)):
                        raise OSError(errno.EBUSY, 'owned observer group not quiescent')
                finally:
                    # ps non deve lasciare un leader irrisolto su timeout.
                    if probe.poll() is None:
                        try:
                            os.killpg(probe.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                        probe.wait(timeout=.5)
                    probe.stdout.close()
                    probe.stderr.close()
            except (OSError, subprocess.SubprocessError) as error:
                self.cleanup_error = error
                raise
            finally:
                child.stdout.close()
                child.stderr.close()
        result['exitCode'] = child.returncode
        result['bytes'] = len(output) + len(errors)
        private = bytes(output) + bytes(errors)
        result['permissionRefused'] = any(token in private.lower() for token in (
            b'operation not permitted', b'permission denied', b'not authorized',
            b'you do not have permission', b'permission to sample'))
        if child.returncode and result['status'] == 'PASS':
            result['status'] = 'BLOCKED'
            result['reason'] = 'observerExit'
        return result, bytes(output), bytes(errors)

    def state(self):
        result, output, _ = self.capture(
            ['/bin/ps', '-p', str(self.process.pid), '-o', 'pid=,ppid=,pgid=,uid=,stat=,lstart='], 1)
        fields = output.decode('utf-8', errors='replace').split()
        expected = [self.process.pid, os.getpid(), self.process.pid, os.geteuid()]
        if (result['status'] != 'PASS' or len(fields) != 10 or
                not all(value.isdigit() for value in fields[:4]) or
                [int(value) for value in fields[:4]] != expected or
                not re.fullmatch(r'[A-Za-z+<>]{1,12}', fields[4])):
            return result, None
        try:
            datetime.datetime.strptime(' '.join(fields[5:]), '%a %b %d %H:%M:%S %Y')
        except ValueError:
            return result, None
        return result, {'pid': expected[0], 'ppid': expected[1], 'pgid': expected[2],
                        'uidMatches': True, 'state': fields[4],
                        'startIdentitySha256': hashlib.sha256(' '.join(fields[5:]).encode()).hexdigest()}

    @staticmethod
    def frames(output, pid):
        text = output.decode('utf-8', errors='replace')
        if not re.search(r'^Process:\s+(?:xcrun|simctl) \[' + str(pid) + r'\]\s*$', text, re.M):
            return {'qualified': False, 'frames': []}
        frames = []
        for line in text.splitlines():
            matched = re.match(r'^[ |+!:]*\d+\s+(.+?) \(in ([A-Za-z0-9_.+-]+)\)', line)
            if not matched:
                continue
            symbol, image = matched.groups()
            if (not re.fullmatch(r'(?:simctl|CoreSimulator|CoreFoundation|Foundation|dyld|SimulatorKit|'
                                 r'lib(?:system_[A-Za-z0-9_]+|dispatch|xpc|objc\.A)\.dylib)', image) or
                    not re.fullmatch(r'(?:[-+]\[[A-Za-z_][A-Za-z0-9_ :]{0,158}\]|'
                                     r'[A-Za-z_][A-Za-z0-9_.$:<>]{0,159})', symbol)):
                continue
            entry = {'image': image, 'symbol': symbol}
            if entry not in frames and len(frames) < 48:
                frames.append(entry)
        return {'qualified': True, 'frames': frames, 'limit': 48}

    @classmethod
    def logs(cls, output, device):
        rows, rejected = [], 0
        tokens = ('launchctl', 'launchd', 'spawn', 'boot', 'booted', 'connection',
                  'error', 'timeout', 'failed', 'simdevice', 'coresimulatorservice',
                  'mach', 'port', 'bootstrap', 'unavailable', 'busy')
        for line in output.splitlines():
            try:
                value = json.loads(line)
                if not isinstance(value, dict):
                    raise ValueError('non-object log row')
            except (ValueError, UnicodeError):
                rejected += 1
                continue
            message, subsystem = value.get('eventMessage'), value.get('subsystem')
            if (not isinstance(message, str) or device.lower() not in message.lower() or
                    not isinstance(subsystem, str) or not re.fullmatch(
                        r'com\.apple\.CoreSimulator(?:\.[A-Za-z0-9_.-]{1,80})?', subsystem)):
                rejected += 1
                continue
            if len(rows) >= 64:
                continue
            row = {'subsystem': subsystem, 'uuidMatches': True,
                   'messageBytes': len(message.encode()),
                   'messageSha256': hashlib.sha256(message.encode()).hexdigest(),
                   'tokens': [token for token in tokens if re.search(
                       r'\b' + token + r'\b', message, re.I)]}
            timestamp = value.get('timestamp')
            if isinstance(timestamp, str) and re.fullmatch(r'[0-9T:.+ Z-]{10,40}', timestamp):
                row['timestamp'] = timestamp
            # category e messageType non vengono copiati senza allowlist.
            if value.get('messageType') in ('Default', 'Info', 'Debug', 'Error', 'Fault'):
                row['messageType'] = value['messageType']
            rows.append(row)
        return {'rows': rows, 'rejected': rejected, 'rowLimit': 64}

    def run(self):
        try:
            # Un milestone diagnostico al primo terzo del budget del comando esistente:
            # nessun ritardo/retry della readiness. Diciotto secondi riservati alle
            # probe+reap; se il gate torna prima, nessun comando osservativo.
            if self.timeout < 28 or self.stop.wait(self.timeout / 3):
                self.emit('readiness-observation-skipped', reason='gateCompletedOrShortBudget')
                return
            before_meta, before = self.state()
            self.emit('readiness-owned-state', phase='before', probe=before_meta, state=before)
            if before is None or self.stop.is_set() or self.process.returncode is not None:
                return
            sample_meta, sample, _ = self.capture(
                ['/usr/bin/sample', str(self.process.pid), '1', '10', '-file', '/dev/stdout'], 3)
            if sample_meta['status'] != 'PASS' or sample_meta.get('permissionRefused'):
                self.emit('readiness-owned-stack', probe=sample_meta, identityStable=False,
                          sample={'qualified': False, 'frames': []})
                return  # Nessuna alternativa o altra probe dopo un rifiuto privacy.
            after_meta, after = self.state()
            stable = bool(after and after['startIdentitySha256'] == before['startIdentitySha256'])
            self.emit('readiness-owned-state', phase='after', probe=after_meta, state=after)
            self.emit('readiness-owned-stack', probe=sample_meta, identityStable=stable,
                      sample=self.frames(sample, self.process.pid) if stable and
                      sample_meta['status'] == 'PASS' else {'qualified': False, 'frames': []})
            if not stable or self.stop.is_set() or self.process.returncode is not None:
                return
            end = datetime.datetime.now(datetime.timezone.utc)
            predicate = ('subsystem BEGINSWITH "com.apple.CoreSimulator" AND '
                         'eventMessage CONTAINS[c] "' + self.device + '"')
            meta, logs, _ = self.capture(
                ['/usr/bin/log', 'show', '--style', 'ndjson', '--predicate', predicate,
                 '--start', self.started.strftime('%Y-%m-%d %H:%M:%S%z'),
                 '--end', end.strftime('%Y-%m-%d %H:%M:%S%z'), '--info', '--debug', '--no-pager'], 3)
            self.emit('readiness-owned-coresimulator', probe=meta,
                      logs=self.logs(logs, self.device) if meta['status'] == 'PASS' else None)
        except (OSError, subprocess.SubprocessError, ValueError) as error:
            self.failure = error
            self.emit('readiness-observation-error', error_type=type(error).__name__,
                      errno=error.errno if isinstance(error, OSError) else None)

    def close(self):
        self.stop.set()
        self.thread.join(timeout=2.5)
        if self.thread.is_alive():
            raise OSError(errno.ETIMEDOUT, 'owned observer cleanup unresolved')
        if self.cleanup_error is not None:
            # La raccolta può essere BLOCKED; reap non verificato resta errore.
            raise OSError(errno.ETIMEDOUT, 'owned observer process reap unresolved')
        self.emit('readiness-observation-end', observerQuiescent=True)


def readiness_owner(record, arguments):
    """Rifiuta prima di qualsiasi probe UUID/context che non siano propri."""
    if not isinstance(record, dict):
        return None
    device, nonce = record.get('device'), record.get('nonce')
    context = {key: os.environ.get(key) for key in (
        'GITHUB_RUN_ID', 'GITHUB_RUN_ATTEMPT', 'GITHUB_JOB', 'GITHUB_SHA')}
    if (not isinstance(device, str) or not ReadinessObservation.UUID.fullmatch(device) or
            not isinstance(nonce, str) or not re.fullmatch(r'[0-9a-f]{32}', nonce) or
            arguments != ['xcrun', 'simctl', 'spawn', device, 'launchctl', 'list'] or
            record.get('name') != 'CMC-Task054-Owned-' + nonce or
            record.get('readinessMethod') != 'owned-descriptor-launchd' or
            record.get('deviceType') != 'com.apple.CoreSimulator.SimDeviceType.iPhone-17' or
            not isinstance(record.get('runtime'), str) or not re.fullmatch(
                r'com\.apple\.CoreSimulator\.SimRuntime\.iOS-26-[0-9]+(?:-[0-9]+)?', record['runtime']) or
            record.get('creationStarted') is not True or record.get('bootstatusCompleted') is not True or
            record.get('cleanup') != 'NOT_RUN' or record.get('processCleanupFailed') or
            record.get('ownerContext') != context or any(not value for value in context.values())):
        return None
    return device


@contextlib.contextmanager
def trace_processes(destination, readiness_record=None, readiness_cleanup_failed=None):
    path = Path(destination)
    # Nessuna operazione se la trace non è acquisibile esclusivamente.
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    original_popen, original_killpg = subprocess.Popen, os.killpg
    origin = time.monotonic_ns()
    sequence = 0
    trace_error = None
    owned_groups = set()
    readiness_consumed = False
    write_lock = threading.Lock()

    with os.fdopen(descriptor, 'w', buffering=1) as stream:
        def emit(event, **metadata):
            nonlocal sequence, trace_error
            with write_lock:
                sequence += 1
                row = dict(sequence=sequence, monotonic_ns=time.monotonic_ns(),
                           elapsed_ns=time.monotonic_ns() - origin, event=event, **metadata)
                try:
                    stream.write(json.dumps(row, sort_keys=True) + '\n')
                except OSError as error:
                    # Non perdere l'handle del processo per un errore di evidence.
                    trace_error = trace_error or error

        class MeasuredPopen(original_popen):
            def __init__(self, arguments, *args, **kwargs):
                self.trace_arguments = arguments
                self.trace_operation = operation(arguments)
                self.trace_owned = kwargs.get('start_new_session') is True
                self.trace_spawn_ns = time.monotonic_ns()
                emit('spawn-start', operation=self.trace_operation, owned_session=self.trace_owned)
                try:
                    super().__init__(arguments, *args, **kwargs)
                except BaseException as error:
                    emit('spawn-error', operation=self.trace_operation,
                         duration_ns=time.monotonic_ns() - self.trace_spawn_ns,
                         error_type=type(error).__name__)
                    raise
                try:
                    observed_group = os.getpgid(self.pid)
                except OSError:
                    observed_group = None
                if self.trace_owned:
                    owned_groups.add(self.pid)
                emit('spawn-end', **self.identity(),
                     duration_ns=time.monotonic_ns() - self.trace_spawn_ns,
                     observed_pgid=observed_group,
                     owned_pgid_confirmed=self.trace_owned and observed_group == self.pid)

            def identity(self):
                return dict(operation=self.trace_operation, pid=self.pid,
                            owned_pgid=self.pid if self.trace_owned else None)

            def communicate(self, *args, **kwargs):
                nonlocal readiness_consumed
                observer = None
                primary = None
                timeout = kwargs.get('timeout', args[1] if len(args) > 1 else None)
                device = readiness_owner(readiness_record(), self.trace_arguments) if (
                    callable(readiness_record) and not readiness_consumed and self.trace_owned) else None
                try:
                    if device is not None and type(timeout) in (int, float) and 0 < timeout <= 30:
                        try:
                            group = os.getpgid(self.pid)
                        except ProcessLookupError:
                            group = None
                        if group == self.pid:
                            readiness_consumed = True
                            observer = ReadinessObservation(
                                self, device, timeout, emit, original_popen)
                    return self.measured_communicate(*args, **kwargs)
                except BaseException as error:
                    primary = error
                    raise
                finally:
                    if observer is not None:
                        try:
                            observer.close()
                        except BaseException as error:
                            emit('readiness-observation-cleanup', status='FAIL',
                                 error_type=type(error).__name__,
                                 errno=error.errno if isinstance(error, OSError) else None,
                                 primary_preserved=primary is not None)
                            if callable(readiness_cleanup_failed):
                                try:
                                    readiness_cleanup_failed()
                                except BaseException as mark_error:
                                    emit('readiness-observation-cleanup-flag', status='FAIL',
                                         error_type=type(mark_error).__name__)
                            if primary is None:
                                raise


            def measured_communicate(self, *args, **kwargs):
                start = time.monotonic_ns()
                timeout = kwargs.get('timeout', args[1] if len(args) > 1 else None)
                emit('communicate-start', **self.identity(), timeout_seconds=timeout)
                try:
                    result = super().communicate(*args, **kwargs)
                except subprocess.TimeoutExpired as error:
                    before = self.returncode
                    # Discrimina leader vivo/uscito; poll può fare reap del leader.
                    observed = super().poll()
                    emit('communicate-timeout', **self.identity(),
                         duration_ns=time.monotonic_ns() - start,
                         timeout_seconds=timeout, returncode_before_poll=before,
                         returncode_after_poll=observed, observer_poll_may_reap=True,
                         leader_state='alive' if observed is None else 'terminated',
                         inherited_pipe='possible' if observed is not None and
                             any(pipe is not None and not pipe.closed for pipe in
                                 (self.stdout, self.stderr)) else 'not_demonstrated',
                         output_complete=False, stdout=output_metadata(error.output),
                         stderr=output_metadata(error.stderr))
                    raise
                except BaseException as error:
                    emit('communicate-error', **self.identity(),
                         duration_ns=time.monotonic_ns() - start,
                         error_type=type(error).__name__)
                    raise
                metadata = owned_ps_metadata(result[0], owned_groups) if (
                    self.trace_operation == 'ps-probe') else {}
                emit('communicate-end', **self.identity(), **metadata,
                     duration_ns=time.monotonic_ns() - start, exit_code=self.returncode,
                     output_complete=True, stdout=output_metadata(result[0]),
                     stderr=output_metadata(result[1]))
                return result

            def wait(self, *args, **kwargs):
                start = time.monotonic_ns()
                timeout = kwargs.get('timeout', args[0] if args else None)
                emit('wait-start', **self.identity(), timeout_seconds=timeout)
                try:
                    result = super().wait(*args, **kwargs)
                except BaseException as error:
                    emit('wait-error', **self.identity(),
                         duration_ns=time.monotonic_ns() - start,
                         error_type=type(error).__name__)
                    raise
                emit('wait-end', **self.identity(), duration_ns=time.monotonic_ns() - start,
                     exit_code=result, reaped=True)
                return result

            def send_signal(self, signum):
                emit('leader-signal-start', **self.identity(), signal=int(signum))
                try:
                    return super().send_signal(signum)
                finally:
                    emit('leader-signal-end', **self.identity(), signal=int(signum),
                         known_exit_code=self.returncode)

        def killpg(group, signum):
            start = time.monotonic_ns()
            emit('group-signal-start', owned_pgid=group, signal=int(signum))
            try:
                result = original_killpg(group, signum)
            except OSError as error:
                emit('group-signal-error', owned_pgid=group, signal=int(signum),
                     duration_ns=time.monotonic_ns() - start,
                     error_type=type(error).__name__, errno=error.errno)
                raise
            emit('group-signal-end', owned_pgid=group, signal=int(signum),
                 duration_ns=time.monotonic_ns() - start)
            return result

        emit('trace-start', schema_version=1, observer_poll_may_reap_at_timeout=True)
        subprocess.Popen, os.killpg = MeasuredPopen, killpg
        try:
            yield emit
        finally:
            subprocess.Popen, os.killpg = original_popen, original_killpg
            emit('trace-end')
            if trace_error is not None:
                raise trace_error

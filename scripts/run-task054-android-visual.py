#!/usr/bin/env python3
"""CI Linux/KVM: AVD proprio, superfici produzione con repository sintetici.

CLI verificata: developer.android.com/tools/{sdkmanager,avdmanager,variables}
e developer.android.com/studio/run/emulator-{commandline,acceleration}.
Nessuna prova backend autenticato o su device fisico deriva da questo runner.
"""
import json
import os
from pathlib import Path
import platform
import shutil
import signal
import socket
import subprocess
import tempfile
import time
import uuid


class Failure(Exception):
    def __init__(self, phase, code, reason):
        super().__init__(f'{phase}: {reason}')
        self.phase = phase
        self.code = code


def owned_group_has_live_members(group):
    """Legge solo PGID/stato, senza nomi, argomenti o identificatori applicativi."""
    try:
        snapshot = subprocess.run(['ps', '-A', '-o', 'pgid=', '-o', 'stat='],
            capture_output=True, text=True, timeout=2, check=False)
    except subprocess.TimeoutExpired as error:
        raise Failure('cleanup-process', 1, 'timeout probe gruppo proprio') from error
    if snapshot.returncode:
        raise Failure('cleanup-process', 1, 'stato del gruppo proprio non verificabile')
    live = False
    for line in snapshot.stdout.splitlines():
        fields = line.split()
        if len(fields) != 2 or not fields[0].isdigit():
            raise Failure('cleanup-process', 1, 'snapshot gruppi non verificabile')
        if int(fields[0]) == group and not fields[1].startswith('Z'):
            live = True
    return live


def _stop_owned_group(process, term_grace):
    """Verifica l'intero PGID proprio; leader uscito non implica gruppo fermo."""
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            process.wait(timeout=1)
            return
        deadline = time.monotonic() + (term_grace if sig == signal.SIGTERM else 5)
        while True:
            if not owned_group_has_live_members(process.pid):
                # Gli zombie non eseguono codice; reap del leader solo a quiescenza.
                process.wait(timeout=1)
                return
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break
            time.sleep(min(0.05, remaining))
        # Nessun segnale tardivo dopo avere osservato un gruppo vuoto/quiescente.
    raise Failure('cleanup-process', 1, 'gruppo proprio non terminato')


def stop_owned_process(process, *, term_grace=5):
    """Drena il gruppo anche se TERM/INT arriva durante il primo cleanup.

    Il primo segnale è differito fino alla quiescenza; il caller conserva il
    proprio tipo di failure e un errore primario già presente. Solo questa fase
    temporanea cambia gli handler del processo che possiede il gruppo.
    """
    signals = (signal.SIGTERM, signal.SIGINT)
    handlers = {signum: signal.getsignal(signum) for signum in signals}
    received = []

    def remember(signum, frame):
        if not received:
            received.append((signum, frame))

    previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK, signals)
    try:
        for signum, handler in handlers.items():
            if handler != signal.SIG_IGN:
                signal.signal(signum, remember)
    finally:
        signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)
    cleanup_error = None
    try:
        _stop_owned_group(process, term_grace)
    except BaseException as error:
        cleanup_error = error
    finally:
        # Il primo handler CLI ignora ulteriori segnali. Evita che un secondo
        # segnale prevalga nella finestra fra restore e dispatch del primo.
        previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK, signals)
        try:
            for signum in signals:
                signal.signal(signum, signal.SIG_IGN if received else handlers[signum])
        finally:
            signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)
    if received:
        signum, frame = received[0]
        try:
            original = handlers[signum]
            if callable(original):
                original(signum, frame)
            else:
                raise Failure('signal', 128 + signum, 'interrotto dopo cleanup proprio')
        except BaseException as error:
            error.owned_cleanup_quiescent = cleanup_error is None
            error.owned_cleanup_error = cleanup_error
            raise
    if cleanup_error is not None:
        raise cleanup_error


class AndroidVisualRunner:
    def __init__(self, repository):
        self.repository = Path(repository)
        self.environment = dict(os.environ)
        self.owned_directory = None
        self.emulator = None
        self.avd_name = 'cmc-task054-' + uuid.uuid4().hex
        self.serial = None
        self.phase = 'preflight'
        self.log = None
        self.avdmanager = None
        self.cleanup_failed = False
        self.revision = None
        self.capture_count = 0

    def command(self, arguments, timeout, *, input_text=None, capture=True,
                check=True):
        child = subprocess.Popen(arguments, cwd=self.repository,
            env=self.environment, start_new_session=True, text=True,
            stdin=subprocess.PIPE if input_text is not None else subprocess.DEVNULL,
            stdout=subprocess.PIPE if capture else None,
            stderr=subprocess.STDOUT if capture else None)
        primary_failure = None
        try:
            output, _ = child.communicate(input=input_text, timeout=timeout)
            if check and child.returncode:
                if output:
                    print(output, flush=True)
                code = child.returncode if child.returncode > 0 else 128 - child.returncode
                raise Failure(self.phase, code, 'comando fallito')
        except subprocess.TimeoutExpired:
            primary_failure = Failure(self.phase, 124, f'timeout {timeout}s')
        except BaseException as error:
            primary_failure = error
        finally:
            try:
                self.stop_command(child)
            except BaseException as error:
                if primary_failure is None:
                    # Anche check=False deve conservare un exit nonzero già
                    # osservato, fermando la lane se il cleanup è interrotto.
                    primary_failure = (Failure(self.phase,
                        child.returncode if child.returncode > 0 else 128 - child.returncode,
                        'exit primario prima del cleanup') if child.returncode else error)
        if primary_failure is not None:
            raise primary_failure
        return child.returncode, (output or '').strip()

    def stop_command(self, child):
        try:
            # Il processo visuale deve poter drenare Flutter e il bridge OS prima
            # del KILL esterno. È grace di cleanup, non timeout build/test.
            stop_owned_process(child,
                term_grace=30 if self.phase == 'native-fixture-capture' else 5)
        except BaseException as error:
            if not getattr(error, 'owned_cleanup_quiescent', False):
                self.cleanup_failed = True
                print(f'FAIL: cleanup command {type(error).__name__}', flush=True)
            if getattr(error, 'owned_cleanup_quiescent', None) is not None:
                raise
            if isinstance(error, Failure) and error.phase == 'signal':
                raise
            if isinstance(error, (SystemExit, KeyboardInterrupt)):
                raise
            raise Failure('cleanup-process', 1, 'cleanup command non verificato') from None

    def wait_ready(self, phase, seconds, arguments, expected):
        self.phase = phase
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            emulator_code = self.emulator.poll()
            if emulator_code is not None:
                raise Failure(phase, emulator_code or 1, 'emulatore terminato')
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break
            code, output = self.command(arguments, min(10, remaining), check=False)
            if code == 0 and expected(output):
                print(f'PASS: {phase}', flush=True)
                return
            # Polling di readiness; nessuna ripetizione di build o test falliti.
            time.sleep(min(1, max(0, deadline - time.monotonic())))
        raise Failure(phase, 124, f'readiness non raggiunta entro {seconds}s')

    def free_console_port(self):
        # Un bind su entrambe le porte evita di scegliere un device già attivo.
        for port in range(5554, 5682, 2):
            with socket.socket() as console, socket.socket() as bridge:
                try:
                    console.bind(('127.0.0.1', port))
                    bridge.bind(('127.0.0.1', port + 1))
                except OSError:
                    continue
                return port
        raise Failure('preflight', 2, 'nessuna coppia di porte libera')

    def execute(self):
        if platform.system() != 'Linux' or platform.machine() != 'x86_64':
            raise Failure(self.phase, 2, 'richiede runner Linux x86_64')
        _, self.revision = self.command(['git', 'rev-parse', 'HEAD'], 15)
        if len(self.revision) != 40 or any(char not in '0123456789abcdef' for char in self.revision):
            raise Failure(self.phase, 2, 'revision Git non verificabile')
        if not os.access('/dev/kvm', os.R_OK | os.W_OK):
            raise Failure(self.phase, 2, 'KVM non accessibile al runner')
        sdk = self.environment.get('ANDROID_HOME') or self.environment.get('ANDROID_SDK_ROOT')
        if not sdk:
            raise Failure(self.phase, 2, 'SDK Android non configurato')
        sdk = Path(sdk)
        sdkmanager = sdk / 'cmdline-tools/latest/bin/sdkmanager'
        self.avdmanager = sdk / 'cmdline-tools/latest/bin/avdmanager'
        emulator = sdk / 'emulator/emulator'
        adb = sdk / 'platform-tools/adb'
        for tool in (sdkmanager, self.avdmanager, adb):
            executable = os.access(tool, os.X_OK)
            print(f'SDK_TOOL name={tool.name} path={tool} executable={executable}', flush=True)
            if not executable:
                raise Failure(self.phase, 2, f'tool SDK richiesto non disponibile: {tool}')
        visual_output = self.repository / 'build/task054/visual'
        if visual_output.exists() and any(visual_output.iterdir()):
            raise Failure(self.phase, 2, 'directory capture non vuota; nessuna cancellazione')
        self.environment['CMC_VISUAL_OUTPUT_DIR'] = str(visual_output)

        self.owned_directory = Path(tempfile.mkdtemp(prefix='cmc-task054-',
            dir=self.environment.get('RUNNER_TEMP')))
        user_directory = self.owned_directory / 'user'
        avd_directory = self.owned_directory / 'avd'
        user_directory.mkdir()
        avd_directory.mkdir()
        self.environment.update(ANDROID_USER_HOME=str(user_directory),
            ANDROID_EMULATOR_HOME=str(user_directory),
            ANDROID_AVD_HOME=str(avd_directory))
        self.phase = 'sdk-install'
        # Usa le licenze già accettate nel runner; non ne accetta di nuove.
        self.command([str(sdkmanager), '--sdk_root=' + str(sdk),
            'emulator', 'system-images;android-35;google_apis;x86_64'], 180)
        executable = os.access(emulator, os.X_OK)
        print(f'SDK_TOOL name=emulator path={emulator} executable={executable}', flush=True)
        if not executable:
            raise Failure(self.phase, 2, 'tool emulator assente dopo SDK install')
        self.phase = 'kvm-check'
        self.command([str(emulator), '-accel-check'], 15)
        self.phase = 'avd-create'
        self.command([str(self.avdmanager), 'create', 'avd', '-n', self.avd_name,
            '-k', 'system-images;android-35;google_apis;x86_64',
            '-p', str(avd_directory / (self.avd_name + '.avd'))], 30,
            input_text='no\n')
        self.phase = 'adb-start'
        self.command([str(adb), 'start-server'], 15)
        port = self.free_console_port()
        self.serial = f'emulator-{port}'
        self.phase = 'emulator-start'
        output = self.repository / 'build/task054/android-emulator.log'
        output.parent.mkdir(parents=True, exist_ok=True)
        self.log = output.open('w')
        self.emulator = subprocess.Popen([str(emulator), '-avd', self.avd_name,
            '-port', str(port), '-no-window', '-no-audio', '-no-snapshot',
            '-accel', 'on', '-memory', '2048', '-gpu', 'swiftshader_indirect'],
            cwd=self.repository, env=self.environment, start_new_session=True,
            stdin=subprocess.DEVNULL, stdout=self.log, stderr=subprocess.STDOUT)
        target = [str(adb), '-s', self.serial]
        self.wait_ready('adb-online', 60, target + ['get-state'],
            lambda text: text == 'device')
        self.phase = 'device-identity'
        _, name = self.command(target + ['emu', 'avd', 'name'], 10)
        if name.splitlines()[0:1] != [self.avd_name]:
            raise Failure(self.phase, 2, 'seriale non associato al proprio AVD')
        self.wait_ready('android-boot', 120,
            target + ['shell', 'getprop', 'sys.boot_completed'],
            lambda text: text == '1')
        self.wait_ready('package-service', 30, target + ['shell', 'pm', 'path', 'android'],
            lambda text: text.startswith('package:'))
        self.phase = 'device-platform'
        _, api = self.command(target + ['shell', 'getprop', 'ro.build.version.sdk'], 10)
        _, abi = self.command(target + ['shell', 'getprop', 'ro.product.cpu.abi'], 10)
        if (api, abi) != ('35', 'x86_64'):
            raise Failure(self.phase, 2, 'API/ABI del device differenti dal contratto')
        self.command(target + ['shell', 'input', 'keyevent', '82'], 10)
        self.phase = 'native-fixture-capture'
        self.environment.update(CMC_OS_FRAME_PLATFORM='android',
            CMC_OS_FRAME_DEVICE=self.serial, CMC_OS_FRAME_ADB=str(adb))
        # Il runner visuale esistente possiede già il timeout drive900 e i suoi figli.
        self.command(['bash', 'scripts/test-task054-visual.sh', '--device', self.serial],
            None, capture=False)
        self.phase = 'capture-completeness'
        self.capture_count = len(list(visual_output.glob('*.png')))
        if self.capture_count != 105:
            raise Failure(self.phase, 1, f'capture attese105, ottenute{self.capture_count}')

    def cleanup(self):
        # Mai adb kill-server, emu kill, shutdown-all o selezione di device altrui.
        deferred_signal = None

        def record(error, resource):
            nonlocal deferred_signal
            if not getattr(error, 'owned_cleanup_quiescent', False):
                self.cleanup_failed = True
                print(f'FAIL: cleanup {resource} {type(error).__name__}', flush=True)
            if isinstance(error, Failure) and error.phase == 'signal' and deferred_signal is None:
                deferred_signal = error

        if self.emulator is not None:
            try:
                stop_owned_process(self.emulator)
            except BaseException as error:
                record(error, 'emulator')
        if self.log is not None:
            try:
                self.log.close()
            except BaseException as error:
                record(error, 'log')
        if self.owned_directory is not None:
            self.phase = 'avd-delete'
            try:
                # Nome random e ANDROID_AVD_HOME isolato, anche dopo create parziale.
                avd_path = self.owned_directory / 'avd' / (self.avd_name + '.avd')
                if avd_path.exists():
                    self.command([str(self.avdmanager), 'delete', 'avd', '-n',
                        self.avd_name], 20)
            except BaseException as error:
                record(error, 'avd')
            finally:
                try:
                    shutil.rmtree(self.owned_directory)
                except BaseException as error:
                    record(error, 'directory')
        if deferred_signal is not None:
            raise deferred_signal

    def run(self):
        code = 0
        failed_phase = None
        try:
            self.execute()
        except Failure as error:
            code = error.code
            failed_phase = self.phase
            print(f'FAIL: {error}', flush=True)
        except OSError as error:
            code = 1
            failed_phase = self.phase
            print(f'FAIL: {self.phase} {type(error).__name__}', flush=True)
        finally:
            try:
                self.cleanup()
            except Failure as error:
                if not code:
                    code, failed_phase = error.code, error.phase
        code = code or (1 if self.cleanup_failed else 0)
        receipt = self.repository / 'build/task054/android-visual-receipt.json'
        receipt.parent.mkdir(parents=True, exist_ok=True)
        receipt.write_text(json.dumps({'evidence_level': 'native_android_fixture',
            'revision': self.revision, 'capture_count': self.capture_count,
            'api': 35, 'abi': 'x86_64', 'exit_code': code,
            'failed_phase': failed_phase, 'cleanup': 'FAIL' if self.cleanup_failed else 'PASS'},
            indent=2) + '\n')
        return code


def interrupted(signum, _frame):
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    raise Failure('signal', 128 + signum, 'esecuzione interrotta')


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    raise SystemExit(AndroidVisualRunner(Path(__file__).resolve().parent.parent).run())

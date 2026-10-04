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
        self.code = code


def stop_owned_process(process):
    """Termina soltanto il gruppo creato da questa istanza del runner."""
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=5)
            return
        except subprocess.TimeoutExpired:
            continue
    raise Failure('cleanup-process', 1, 'gruppo proprio non terminato')


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
        try:
            output, _ = child.communicate(input=input_text, timeout=timeout)
        except subprocess.TimeoutExpired:
            self.stop_command(child)
            raise Failure(self.phase, 124, f'timeout {timeout}s')
        except BaseException:
            self.stop_command(child)
            raise
        if check and child.returncode:
            if output:
                print(output, flush=True)
            raise Failure(self.phase, child.returncode, 'comando fallito')
        return child.returncode, (output or '').strip()

    def stop_command(self, child):
        try:
            stop_owned_process(child)
        except (OSError, Failure) as error:
            self.cleanup_failed = True
            print(f'FAIL: cleanup command {type(error).__name__}', flush=True)

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
        for tool in (sdkmanager, self.avdmanager, emulator, adb):
            if not os.access(tool, os.X_OK):
                raise Failure(self.phase, 2, 'tool SDK richiesto non disponibile')
        _, self.revision = self.command(['git', 'rev-parse', 'HEAD'], 15)
        if len(self.revision) != 40 or any(char not in '0123456789abcdef' for char in self.revision):
            raise Failure(self.phase, 2, 'revision Git non verificabile')
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
            'system-images;android-35;google_apis;x86_64'], 180)
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
        # Il runner visuale esistente possiede già il timeout drive900 e i suoi figli.
        self.command(['bash', 'scripts/test-task054-visual.sh', '--device', self.serial],
            None, capture=False)
        self.phase = 'capture-completeness'
        self.capture_count = len(list(visual_output.glob('*.png')))
        if self.capture_count != 103:
            raise Failure(self.phase, 1, f'capture attese103, ottenute{self.capture_count}')

    def cleanup(self):
        # Mai adb kill-server, emu kill, shutdown-all o selezione di device altrui.
        if self.emulator is not None:
            try:
                stop_owned_process(self.emulator)
            except (OSError, Failure) as error:
                self.cleanup_failed = True
                print(f'FAIL: cleanup emulator {type(error).__name__}', flush=True)
        if self.log is not None:
            self.log.close()
        if self.owned_directory is not None:
            self.phase = 'avd-delete'
            try:
                # Nome random e ANDROID_AVD_HOME isolato, anche dopo create parziale.
                avd_path = self.owned_directory / 'avd' / (self.avd_name + '.avd')
                if avd_path.exists():
                    self.command([str(self.avdmanager), 'delete', 'avd', '-n',
                        self.avd_name], 20)
            except (OSError, Failure) as error:
                self.cleanup_failed = True
                print(f'FAIL: cleanup avd {type(error).__name__}', flush=True)
            finally:
                try:
                    shutil.rmtree(self.owned_directory)
                except OSError as error:
                    self.cleanup_failed = True
                    print(f'FAIL: cleanup directory {type(error).__name__}', flush=True)

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
            self.cleanup()
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
    raise Failure('signal', 128 + signum, 'esecuzione interrotta')


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    raise SystemExit(AndroidVisualRunner(Path(__file__).resolve().parent.parent).run())

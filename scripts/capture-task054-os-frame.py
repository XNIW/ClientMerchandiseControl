#!/usr/bin/env python3
"""Bridge TEST ONLY: frame OS sincronizzato, senza attestare acceptance IME.

CLI Android verificata in https://developer.android.com/tools/adb#screencap:
adb -s <serial> exec-out screencap -p. La grammatica iOS deriva da
`xcrun simctl help io`: simctl io <UUID> screenshot --type=png <file>.
Il caller fornisce esclusivamente il proprio device, senza discovery o boot.
Il dump input_method resta in memoria: persistono soltanto due boolean nullable.
"""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import tempfile


_cleanup_spec = importlib.util.spec_from_file_location(
    'cmc_task054_owned_process',
    Path(__file__).with_name('run-task054-android-visual.py'))
_cleanup_module = importlib.util.module_from_spec(_cleanup_spec)
_cleanup_spec.loader.exec_module(_cleanup_module)
stop_owned_process = _cleanup_module.stop_owned_process

PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'
FLAGS = ('mInputShown', 'mIsInputViewShown')


class Failure(Exception):
    def __init__(self, phase, code):
        super().__init__(phase)
        self.phase = phase
        self.code = code


def parse_ime_flags(output):
    """Ogni campo deve comparire esattamente una volta con true/false esatto."""
    result = {}
    for field in FLAGS:
        matches = re.findall(
            rb'(?<![A-Za-z0-9_])' + field.encode('ascii') + rb'\s*=\s*(\S+)',
            output)
        result[field] = (matches[0] == b'true' if len(matches) == 1 and
                         matches[0] in (b'true', b'false') else None)
    return result


class OSFrameCapture:
    def __init__(self, repository, name, platform, device, environment=None):
        self.repository = Path(repository).resolve()
        self.name = name
        self.platform = platform
        self.device = device
        self.environment = dict(os.environ if environment is None else environment)
        self.output = self.repository / 'build/task054/os-visual'
        self.image = self.output / (name + '.png')
        self.receipt_path = self.output / (name + '.json')
        self.receipt = {
            'gitHead': None, 'source': 'os_display', 'platform': platform,
            'marker': name, 'frame_status': 'NOT_RUN', 'probe_status': 'NOT_RUN',
            'mInputShown': None, 'mIsInputViewShown': None,
            'ime_acceptance': 'NOT_RUN', 'frame_sha256': None,
            'exit_code': 2, 'failed_phase': None, 'cleanup_status': 'PASS',
        }
        self.adb = None
        self.phase = 'preflight'

    def validate(self):
        # Nessun argomento non validato entra in un comando o in un path scritto.
        if (not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]{0,99}', self.name) or
                not re.search(r'(^|-)focus(-|$)', self.name)):
            raise Failure('preflight', 2)
        if self.platform == 'android':
            serial = re.fullmatch(r'emulator-([0-9]{4})', self.device)
            if (serial is None or not 5554 <= int(serial[1]) <= 5682 or
                    int(serial[1]) % 2):
                raise Failure('preflight', 2)
            configured = self.environment.get('CMC_OS_FRAME_ADB')
            if configured is None:
                home = self.environment.get('ANDROID_HOME')
                if not home or not Path(home).is_absolute():
                    raise Failure('preflight', 2)
                configured = str(Path(home) / 'platform-tools/adb')
            adb = Path(configured)
            if not adb.is_absolute() or not adb.is_file() or not os.access(adb, os.X_OK):
                raise Failure('preflight', 2)
            self.adb = str(adb)
        elif self.platform == 'ios':
            if not re.fullmatch(
                    r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}',
                    self.device):
                raise Failure('preflight', 2)
        else:
            raise Failure('preflight', 2)
        for directory in (self.repository / 'build',
                          self.repository / 'build/task054', self.output):
            if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
                raise Failure('preflight', 2)
        for path in (self.image, self.receipt_path):
            if path.exists() or path.is_symlink():
                raise Failure('preflight', 2)

    def command(self, arguments, timeout, phase):
        self.phase = phase
        child = subprocess.Popen(arguments, cwd=self.repository, env=self.environment,
            start_new_session=True, shell=False, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        primary_failure = None
        try:
            try:
                output, _ = child.communicate(timeout=timeout)
            except subprocess.TimeoutExpired:
                raise Failure(phase, 124) from None
            if child.returncode:
                code = child.returncode if child.returncode > 0 else 128 - child.returncode
                raise Failure(phase, code)
            return output or b''
        except BaseException as error:
            primary_failure = error
            raise
        finally:
            # Anche un leader uscito potrebbe avere discendenti nel PGID proprio.
            # Mai kill-server, shutdown/delete device o gruppi del caller.
            try:
                stop_owned_process(child)
            except Exception as error:
                self.receipt['cleanup_status'] = 'FAIL'
                if primary_failure is None:
                    if isinstance(error, Failure) and error.phase == 'signal':
                        raise
                    raise Failure('cleanup', 1) from None

    def save_png(self, contents):
        if len(contents) <= len(PNG_SIGNATURE) or not contents.startswith(PNG_SIGNATURE):
            raise Failure('screen', 1)
        # Il create esclusivo conserva anche un file apparso dopo il preflight.
        with self.image.open('xb') as destination:
            destination.write(contents)
        self.receipt['frame_sha256'] = hashlib.sha256(contents).hexdigest()
        self.receipt['frame_status'] = 'PASS'

    def capture(self):
        revision = self.command(['git', 'rev-parse', 'HEAD'], 5, 'git').strip()
        if not re.fullmatch(rb'[0-9a-f]{40}', revision):
            raise Failure('git', 1)
        self.receipt['gitHead'] = revision.decode('ascii')
        self.receipt['frame_status'] = 'FAIL'
        if self.platform == 'android':
            target = [self.adb, '-s', self.device]
            frame = self.command(target + ['exec-out', 'screencap', '-p'], 10, 'screen')
            self.save_png(frame)
            self.receipt['probe_status'] = 'FAIL'
            dump = self.command(target + ['shell', 'dumpsys', 'input_method'], 5, 'probe')
            self.receipt.update(parse_ime_flags(dump))
            if any(self.receipt[field] is None for field in FLAGS):
                raise Failure('probe', 1)
            self.receipt['probe_status'] = 'PASS'
        else:
            # simctl scrive in un path temporaneo proprio; il nome finale non è
            # mai passato a un tool che potrebbe sovrascrivere file preesistenti.
            directory = tempfile.TemporaryDirectory(prefix='cmc-os-frame-', dir=self.output)
            primary_failure = None
            try:
                temporary_frame = Path(directory.name) / 'frame.png'
                self.command(['xcrun', 'simctl', 'io', self.device, 'screenshot',
                    '--type=png', str(temporary_frame)], 10, 'screen')
                self.save_png(temporary_frame.read_bytes())
            except BaseException as error:
                primary_failure = error
                raise
            finally:
                try:
                    directory.cleanup()
                except Exception as error:
                    self.receipt['cleanup_status'] = 'FAIL'
                    if primary_failure is None:
                        if isinstance(error, Failure) and error.phase == 'signal':
                            raise
                        raise Failure('cleanup', 1) from None
            # Nessun boolean Android né risultato IME viene inferito dal PNG iOS.

    def run(self):
        try:
            self.validate()
        except Failure as error:
            print('FAIL: preflight OS frame', flush=True)
            return error.code
        # Il receipt viene riservato prima delle azioni OS: nessun overwrite,
        # neppure con due richieste concorrenti per lo stesso marker.
        try:
            self.output.mkdir(parents=True, exist_ok=True)
            receipt_file = self.receipt_path.open('x')
        except OSError:
            print('FAIL: output OS frame', flush=True)
            return 2
        code = 0
        try:
            self.capture()
        except Failure as error:
            code = error.code
            self.receipt['failed_phase'] = error.phase
        except OSError:
            code = 1
            self.receipt['failed_phase'] = self.phase
        except Exception:
            # Anche un errore inatteso produce una ricevuta FAIL, senza raw output.
            code = 1
            self.receipt['failed_phase'] = self.phase
        finally:
            if not code and self.receipt['cleanup_status'] == 'FAIL':
                code = 1
                self.receipt['failed_phase'] = 'cleanup'
            self.receipt['exit_code'] = code
            try:
                with receipt_file:
                    receipt_file.write(json.dumps(self.receipt, indent=2) + '\n')
            except OSError:
                code = code or 1
        print('OS_FRAME_RESULT=' + ('PASS' if code == 0 else 'FAIL'), flush=True)
        return code


class SafeArgumentParser(argparse.ArgumentParser):
    def error(self, _message):
        # argparse normalmente ripete il valore ricevuto: qui non si espongono ID.
        self.exit(2, 'FAIL: argomenti OS frame non validi\n')


def interrupted(signum, _frame):
    # Il primo segnale diventa la causa primaria; ulteriori segnali non impediscono
    # il cleanup bounded dei soli command group creati da questo processo.
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    raise Failure('signal', 128 + signum)


def main(arguments=None):
    parser = SafeArgumentParser(description=__doc__)
    parser.add_argument('--name', required=True)
    parser.add_argument('--platform', required=True, choices=('android', 'ios'))
    parser.add_argument('--device', required=True)
    options = parser.parse_args(arguments)
    return OSFrameCapture(Path(__file__).resolve().parent.parent,
        options.name, options.platform, options.device).run()


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    raise SystemExit(main())

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
import struct
import subprocess
import tempfile
import zlib


_cleanup_spec = importlib.util.spec_from_file_location(
    'cmc_task054_owned_process',
    Path(__file__).with_name('run-task054-android-visual.py'))
_cleanup_module = importlib.util.module_from_spec(_cleanup_spec)
_cleanup_spec.loader.exec_module(_cleanup_module)
stop_owned_process = _cleanup_module.stop_owned_process

PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'
FLAGS = ('mInputShown', 'mIsInputViewShown')
MAX_PNG_PIXELS = 32 * 1024 * 1024
MAX_PNG_BYTES = 128 * 1024 * 1024
PNG_TYPES = {0: (1, (1, 2, 4, 8, 16)), 2: (3, (8, 16)),
             3: (1, (1, 2, 4, 8)), 4: (2, (8, 16)), 6: (4, (8, 16))}
ADAM7 = ((0, 0, 8, 8), (4, 0, 8, 8), (0, 4, 4, 8), (2, 0, 4, 4),
         (0, 2, 2, 4), (1, 0, 2, 2), (0, 1, 1, 2))


class Failure(Exception):
    def __init__(self, phase, code):
        super().__init__(phase)
        self.phase = phase
        self.code = code


def validate_png(contents):
    """PNG3: CRC, chunk critici, zlib completo e scanline decodificabili.

    Profilo statico bounded per i frame dei device propri. Supporta tutti i color
    type/bit depth PNG e Adam7; i chunk ancillary non cambiano la decodificabilità
    dei pixel e restano opachi. Fonte: https://www.w3.org/TR/png-3/.
    """
    if not contents.startswith(PNG_SIGNATURE) or len(contents) > MAX_PNG_BYTES:
        raise Failure('screen', 1)
    offset, header, palette = len(PNG_SIGNATURE), None, None
    image_data, last_idat_length = [], 0
    idat_ended, ended = False, False
    while offset < len(contents):
        if len(contents) - offset < 12:
            raise Failure('screen', 1)
        length = struct.unpack_from('>I', contents, offset)[0]
        kind = contents[offset + 4:offset + 8]
        end = offset + length + 12
        if (length > 0x7fffffff or end > len(contents) or
                not re.fullmatch(rb'[A-Za-z]{4}', kind) or kind[2] & 32):
            raise Failure('screen', 1)
        payload = contents[offset + 8:end - 4]
        crc = struct.unpack_from('>I', contents, end - 4)[0]
        if zlib.crc32(kind + payload) != crc:
            raise Failure('screen', 1)
        if header is None and kind != b'IHDR':
            raise Failure('screen', 1)
        if kind == b'IHDR':
            if header is not None or length != 13:
                raise Failure('screen', 1)
            header = struct.unpack('>IIBBBBB', payload)
            width, height, depth, color, compression, filtering, interlace = header
            if (not 0 < width <= 0x7fffffff or not 0 < height <= 0x7fffffff or
                    width * height > MAX_PNG_PIXELS or color not in PNG_TYPES or
                    depth not in PNG_TYPES[color][1] or compression != 0 or
                    filtering != 0 or interlace not in (0, 1)):
                raise Failure('screen', 1)
        elif kind == b'PLTE':
            if (palette is not None or image_data or color in (0, 4) or
                    not 0 < length <= 768 or length % 3 or
                    color == 3 and length // 3 > 1 << depth):
                raise Failure('screen', 1)
            palette = length // 3
        elif kind == b'IDAT':
            if idat_ended or color == 3 and palette is None:
                raise Failure('screen', 1)
            image_data.append(payload)
            last_idat_length = length
        elif kind == b'IEND':
            if length or not image_data or end != len(contents):
                raise Failure('screen', 1)
            ended = True
        else:
            if not kind[0] & 32:  # Unknown critical: nessuna decodifica sicura.
                raise Failure('screen', 1)
            if image_data:
                idat_ended = True
        offset = end
    if not ended:
        raise Failure('screen', 1)

    bits = PNG_TYPES[color][0] * depth
    passes = []
    for x, y, dx, dy in (ADAM7 if interlace else ((0, 0, 1, 1),)):
        pass_width = max(0, (width - x + dx - 1) // dx)
        pass_height = max(0, (height - y + dy - 1) // dy)
        if pass_width and pass_height:
            passes.append((pass_width, pass_height, (pass_width * bits + 7) // 8))
    expected = sum(rows * (row_bytes + 1) for _, rows, row_bytes in passes)
    if expected > MAX_PNG_BYTES:
        raise Failure('screen', 1)
    decoder = zlib.decompressobj()
    try:
        decoded = decoder.decompress(b''.join(image_data), expected + 1)
    except zlib.error:
        raise Failure('screen', 1) from None
    if (not decoder.eof or len(decoded) != expected or decoder.unconsumed_tail or
            len(decoder.unused_data) > last_idat_length):
        raise Failure('screen', 1)
    # PNG3 §11.2.3 permette di ignorare byte inutilizzati nell'ULTIMO IDAT.
    position = 0
    for pass_width, rows, row_bytes in passes:
        previous = bytearray(row_bytes) if color == 3 else None
        for _ in range(rows):
            filter_type = decoded[position]
            if filter_type > 4:
                raise Failure('screen', 1)
            position += 1
            if color == 3:
                row = bytearray(decoded[position:position + row_bytes])
                for index in range(row_bytes):
                    left = row[index - 1] if index else 0
                    above = previous[index]
                    upper_left = previous[index - 1] if index else 0
                    if filter_type == 1:
                        prediction = left
                    elif filter_type == 2:
                        prediction = above
                    elif filter_type == 3:
                        prediction = (left + above) // 2
                    elif filter_type == 4:
                        estimate = left + above - upper_left
                        distances = (abs(estimate - left), abs(estimate - above),
                                     abs(estimate - upper_left))
                        prediction = (left, above, upper_left)[distances.index(min(distances))]
                    else:
                        prediction = 0
                    row[index] = (row[index] + prediction) & 255
                for pixel in range(pass_width):
                    bit = pixel * depth
                    value = (row[bit // 8] >> (8 - depth - bit % 8)) & ((1 << depth) - 1)
                    if value >= palette:
                        raise Failure('screen', 1)
                previous = row
            position += row_bytes


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
                if not getattr(error, 'owned_cleanup_quiescent', False):
                    self.receipt['cleanup_status'] = 'FAIL'
                if primary_failure is None:
                    if isinstance(error, Failure) and error.phase == 'signal':
                        raise
                    raise Failure('cleanup', 1) from None

    def save_png(self, contents):
        validate_png(contents)
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

#!/usr/bin/env python3
"""Anteprime QA PNG separate dai raw; nessuna cattura o approvazione visuale.

sips macOS ridimensiona l'intero frame, senza crop né formati lossy. Il manifest
lega byte e dimensioni raw/preview: i dettagli critici richiedono ancora il raw.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import shutil
import signal
import struct
import subprocess
import time


_spec = importlib.util.spec_from_file_location('cmc_preview_png',
    Path(__file__).with_name('capture-task054-os-frame.py'))
_png = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_png)

MAX_EDGE = 1000
TOTAL_SECONDS = 45
TOOL_SECONDS = 5


class Failure(Exception):
    pass


class ToolFailure(Failure):
    def __init__(self, primary, cleanup):
        self.primary_type = type(primary).__name__ if primary else None
        self.cleanup_type = type(cleanup).__name__ if cleanup else None


def run_tool(arguments, timeout):
    """Solo PGID allocato dal caller; output dei tool non finisce nei log."""
    child = subprocess.Popen(arguments, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, shell=False,
        start_new_session=True)
    primary, cleanup, output = None, None, b''
    try:
        output, _ = child.communicate(timeout=timeout)
        if child.returncode:
            raise Failure('tool non riuscito')
    except BaseException as error:
        primary = error
    finally:
        try:
            _png.stop_owned_process(child)
        except BaseException as error:
            if getattr(error, 'owned_cleanup_quiescent', None) is None:
                error = _png._cleanup_module.finish_owned_cleanup_after_error(child, error)
            cleanup = error
    if isinstance(primary, (SystemExit, KeyboardInterrupt)):
        raise primary
    if isinstance(cleanup, (SystemExit, KeyboardInterrupt)):
        raise cleanup
    if primary is not None or cleanup is not None:
        raise ToolFailure(primary, cleanup)
    return output


def dimensions(contents):
    _png.validate_png(contents)
    return struct.unpack_from('>II', contents, 16)


def sha256(contents):
    return hashlib.sha256(contents).hexdigest()


def create_previews(source, output, revision, *, run=run_tool,
                    clock=time.monotonic):
    """Trasforma soltanto visual/*.png e os-visual/*.png già esistenti."""
    source = Path(source).resolve()
    output = Path(output).resolve()
    sources = [source / name for name in ('visual', 'os-visual')]
    if (not re.fullmatch(r'[0-9a-f]{40}', revision) or output == source or
            any(output == p or output.is_relative_to(p) or
                p.is_relative_to(output) for p in sources)):
        raise Failure('contesto preview non valido')
    # Non riusa directory precedenti o scrive sopra catture/artefatti altrui.
    output.mkdir(parents=True, mode=0o700, exist_ok=False)
    start = clock()
    manifest = {
        'schemaVersion': 1,
        'sourceCheckout': revision,
        'scope': 'preview_qa; raw richiesto per zoom critico; non approvazione UX',
        'status': 'FAIL',
        'maxEdgePixels': MAX_EDGE,
        'encoding': 'PNG lossless; il resampling cambia i pixel della preview',
        'totalBudgetSeconds': TOTAL_SECONDS,
        'files': [],
    }
    code, current_preview = 1, None
    try:
        paths = []
        for directory in sources:
            if directory.is_symlink():
                raise Failure('directory raw simbolica')
            for path in sorted(directory.glob('*.png')):
                if (path.is_symlink() or not path.is_file() or
                        not re.fullmatch(r'[a-zA-Z0-9-]+\.png', path.name)):
                    raise Failure('file raw non valido')
                paths.append(path)
        if not paths:
            manifest.update(status='NOT_RUN', reason='nessuna cattura raw disponibile')
            code = 0
        else:
            for path in paths:
                remaining = TOTAL_SECONDS - (clock() - start)
                if remaining <= 0:
                    raise Failure('budget preview esaurito')
                contents = path.read_bytes()
                width, height = dimensions(contents)
                relative = path.relative_to(source)
                preview = output / relative
                current_preview = preview
                preview.parent.mkdir(mode=0o700, exist_ok=True)
                if max(width, height) <= MAX_EDGE:
                    # Nessun upscale; il file già piccolo resta byte-identico.
                    shutil.copyfile(path, preview)
                    operation = 'copy_without_resampling'
                else:
                    run(['/usr/bin/sips', '--setProperty', 'format', 'png',
                         '--resampleHeightWidthMax', str(MAX_EDGE), str(path),
                         '--out', str(preview)], min(TOOL_SECONDS, remaining))
                    operation = 'sips_resample_height_width_max'
                preview.chmod(0o600)
                transformed = preview.read_bytes()
                new_width, new_height = dimensions(transformed)
                if (new_width > width or new_height > height or
                        max(new_width, new_height) > MAX_EDGE or
                        abs(new_width * height - new_height * width) > max(width, height)):
                    raise Failure('dimensioni preview non conformi')
                if path.read_bytes() != contents:
                    raise Failure('raw modificato durante la trasformazione')
                manifest['files'].append({
                    'rawPath': relative.as_posix(),
                    'previewPath': relative.as_posix(),
                    'rawSha256': sha256(contents),
                    'previewSha256': sha256(transformed),
                    'rawBytes': len(contents),
                    'previewBytes': len(transformed),
                    'rawDimensions': [width, height],
                    'previewDimensions': [new_width, new_height],
                    'transform': operation,
                    'crop': False,
                })
                current_preview = None
            if clock() - start > TOTAL_SECONDS:
                raise Failure('budget preview esaurito')
            manifest['status'] = 'PASS'
            code = 0
    except Exception as error:
        # Solo categoria, mai argv/output o percorsi host nei messaggi pubblici.
        manifest['failureType'] = type(error).__name__
        if isinstance(error, ToolFailure):
            manifest['toolFailure'] = {'primaryType': error.primary_type,
                                      'cleanupType': error.cleanup_type}
    finally:
        if current_preview is not None and current_preview.exists():
            current_preview.unlink()
        manifest['elapsedMonotonicSeconds'] = clock() - start
        manifest['rawCounts'] = {name: len(list((source / name).glob('*.png')))
                                 for name in ('visual', 'os-visual')}
        manifest['previewCounts'] = {name: sum(
            item['previewPath'].startswith(name + '/') for item in manifest['files'])
                                    for name in ('visual', 'os-visual')}
        receipt = output / 'manifest.json'
        receipt.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')
        receipt.chmod(0o600)
    return code


def interrupted(signum, _frame):
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    raise SystemExit(128 + signum)


def main():
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    root = Path(__file__).resolve().parent.parent
    revision = run_tool(['git', '-C', str(root), 'rev-parse', 'HEAD'], 5).decode().strip()
    code = create_previews(root / 'build/task054',
        root / 'build/task054/ios-visual-preview', revision)
    status = json.loads((root / 'build/task054/ios-visual-preview/manifest.json').read_text())['status']
    print('IOS_PREVIEW_RESULT=' + status)
    return code


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, Failure, _png.Failure, subprocess.SubprocessError) as error:
        print('IOS_PREVIEW_RESULT=FAIL ' + type(error).__name__)
        raise SystemExit(1) from None

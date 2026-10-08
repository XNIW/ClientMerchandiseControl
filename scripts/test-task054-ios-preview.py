#!/usr/bin/env python3
"""Regressioni preview: raw immutabili, nessun device/build o dipendenza PIL."""
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest
import zlib
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location('cmc_preview',
    Path(__file__).with_name('create-task054-ios-preview.py'))
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
REVISION = 'a' * 40


def chunk(kind, payload=b''):
    return (struct.pack('>I', len(payload)) + kind + payload +
            struct.pack('>I', zlib.crc32(kind + payload)))


def png(width, height):
    header = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    pixels = (b'\0' + b'\x13\x58\x96' * width) * height
    return (MODULE._png.PNG_SIGNATURE + chunk(b'IHDR', header) +
            chunk(b'IDAT', zlib.compress(pixels)) + chunk(b'IEND'))


class PreviewTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='cmc-preview-')
        self.root = Path(self.temp.name)
        self.source = self.root / 'raw'
        self.output = self.root / 'preview'
        self.commands = []

    def tearDown(self):
        self.temp.cleanup()

    def raw(self, name='visual/01-field-focus.png', width=600, height=1200):
        path = self.source / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png(width, height))
        return path

    def resize(self, arguments, timeout):
        self.commands.append((arguments, timeout))
        self.assertEqual(arguments[:5], ['/usr/bin/sips', '--setProperty',
            'format', 'png', '--resampleHeightWidthMax'])
        self.assertEqual(arguments[5], '1000')
        self.assertEqual(arguments[7], '--out')
        width, height = MODULE.dimensions(Path(arguments[6]).read_bytes())
        ratio = 1000 / max(width, height)
        Path(arguments[-1]).write_bytes(png(round(width * ratio), round(height * ratio)))
        return b''

    def execute(self, **kwargs):
        return MODULE.create_previews(self.source, self.output, REVISION,
            run=kwargs.pop('run', self.resize), **kwargs)

    def receipt(self):
        return json.loads((self.output / 'manifest.json').read_text())

    def test_mixed_frames_have_hash_dimensions_relative_paths_and_no_crop(self):
        paths = [self.raw(), self.raw('os-visual/01-field-focus.png', 1200, 600)]
        before = [path.read_bytes() for path in paths]
        self.assertEqual(self.execute(), 0)
        result = self.receipt()
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(result['sourceCheckout'], REVISION)
        self.assertEqual(result['rawCounts'], {'visual': 1, 'os-visual': 1})
        self.assertEqual(result['previewCounts'], result['rawCounts'])
        self.assertIn('raw richiesto', result['scope'])
        for item in result['files']:
            raw = self.source / item['rawPath']
            preview = self.output / item['previewPath']
            self.assertEqual(item['rawSha256'], hashlib.sha256(raw.read_bytes()).hexdigest())
            self.assertEqual(item['previewSha256'], hashlib.sha256(preview.read_bytes()).hexdigest())
            self.assertEqual(item['rawDimensions'], list(MODULE.dimensions(raw.read_bytes())))
            self.assertEqual(item['previewDimensions'], list(MODULE.dimensions(preview.read_bytes())))
            self.assertEqual(max(item['previewDimensions']), 1000)
            self.assertIs(item['crop'], False)
            self.assertEqual(item['transform'], 'sips_resample_height_width_max')
            self.assertEqual(preview.stat().st_mode & 0o777, 0o600)
        self.assertEqual(before, [path.read_bytes() for path in paths])
        self.assertTrue(all(timeout == 5 for _, timeout in self.commands))

    def test_small_png_is_byte_identical_without_upscale_or_tool(self):
        raw = self.raw(width=320, height=568)
        self.assertEqual(self.execute(), 0)
        item = self.receipt()['files'][0]
        self.assertEqual(item['transform'], 'copy_without_resampling')
        self.assertEqual(item['rawSha256'], item['previewSha256'])
        self.assertEqual((self.output / item['previewPath']).read_bytes(), raw.read_bytes())
        self.assertEqual(self.commands, [])

    def test_no_captures_is_not_run_instead_of_pass(self):
        self.assertEqual(self.execute(), 0)
        result = self.receipt()
        self.assertEqual(result['status'], 'NOT_RUN')
        self.assertEqual(result['files'], [])

    def test_corrupt_raw_fails_without_preview(self):
        self.raw().write_bytes(b'not a PNG')
        self.assertEqual(self.execute(), 1)
        self.assertEqual(self.receipt()['status'], 'FAIL')
        self.assertEqual(list(self.output.rglob('*.png')), [])

    def test_invalid_preview_is_removed_not_uploaded_unmapped(self):
        self.raw()
        def invalid(arguments, _timeout):
            Path(arguments[-1]).write_bytes(b'broken')
        self.assertEqual(self.execute(run=invalid), 1)
        self.assertEqual(list(self.output.rglob('*.png')), [])
        self.assertEqual(self.receipt()['files'], [])

    def test_oversize_and_distortion_fail(self):
        for dimensions in [(1001, 2002), (1000, 1000)]:
            with self.subTest(dimensions=dimensions), tempfile.TemporaryDirectory() as temp:
                output = Path(temp) / 'preview'
                self.raw()
                def wrong(arguments, _timeout):
                    Path(arguments[-1]).write_bytes(png(*dimensions))
                self.assertEqual(MODULE.create_previews(self.source, output, REVISION,
                    run=wrong), 1)
                self.assertEqual(list(output.rglob('*.png')), [])

    def test_raw_mutation_is_fail_even_with_valid_preview(self):
        raw = self.raw()
        def mutate(arguments, timeout):
            self.resize(arguments, timeout)
            raw.write_bytes(png(601, 1200))
        self.assertEqual(self.execute(run=mutate), 1)
        self.assertEqual(self.receipt()['files'], [])
        self.assertEqual(list(self.output.rglob('*.png')), [])

    def test_symlink_raw_and_directory_are_rejected(self):
        for directory in (False, True):
            with self.subTest(directory=directory), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                source = root / 'raw'
                source.mkdir()
                target = root / 'external'
                target.mkdir()
                (target / '01.png').write_bytes(png(1, 1))
                if directory:
                    (source / 'visual').symlink_to(target, target_is_directory=True)
                else:
                    (source / 'visual').mkdir()
                    (source / 'visual/01.png').symlink_to(target / '01.png')
                self.assertEqual(MODULE.create_previews(source, root / 'preview',
                    REVISION, run=self.resize), 1)

    def test_unsafe_name_is_rejected_without_tool_output(self):
        self.raw('visual/PRIVATE field.png')
        self.assertEqual(self.execute(), 1)
        self.assertNotIn('PRIVATE', (self.output / 'manifest.json').read_text())
        self.assertEqual(self.commands, [])

    def test_existing_output_is_never_reused_or_overwritten(self):
        self.output.mkdir()
        sentinel = self.output / 'foreign.txt'
        sentinel.write_text('preserve')
        with self.assertRaises(FileExistsError):
            self.execute()
        self.assertEqual(sentinel.read_text(), 'preserve')

    def test_output_cannot_contain_or_overlap_raw_directories(self):
        raw = self.raw()
        before = raw.read_bytes()
        for output in [self.source, self.source / 'visual',
                       self.source / 'visual/nested', self.root]:
            with self.subTest(output=output), self.assertRaises(MODULE.Failure):
                MODULE.create_previews(self.source, output, REVISION, run=self.resize)
        self.assertEqual(before, raw.read_bytes())

    def test_overall_budget_expired_is_fail_and_preserves_manifest(self):
        self.raw()
        ticks = iter([0, 61, 61])
        self.assertEqual(self.execute(clock=lambda: next(ticks)), 1)
        self.assertEqual(self.receipt()['status'], 'FAIL')
        self.assertEqual(self.commands, [])

    def test_last_transform_cannot_report_pass_after_budget(self):
        self.raw()
        ticks = iter([0, 0, 61, 61])
        self.assertEqual(self.execute(clock=lambda: next(ticks)), 1)
        self.assertEqual(self.receipt()['status'], 'FAIL')
        self.assertEqual(len(self.receipt()['files']), 1)

    def test_tool_timeout_and_cleanup_failure_remain_distinct(self):
        child = unittest.mock.Mock(pid=12345, returncode=None)
        child.communicate.side_effect = subprocess.TimeoutExpired('private argv', 5)
        cleanup_error = RuntimeError('private cleanup')
        cleanup_error.owned_cleanup_quiescent = False
        with patch.object(MODULE.subprocess, 'Popen', return_value=child) as popen, \
             patch.object(MODULE._png, 'stop_owned_process', side_effect=cleanup_error):
            with self.assertRaises(MODULE.ToolFailure) as result:
                MODULE.run_tool(['/usr/bin/sips', 'private path'], 5)
        self.assertEqual(result.exception.primary_type, 'TimeoutExpired')
        self.assertEqual(result.exception.cleanup_type, 'RuntimeError')
        self.assertEqual(popen.call_args.kwargs, {'stdin': subprocess.DEVNULL,
            'stdout': subprocess.PIPE, 'stderr': subprocess.DEVNULL,
            'shell': False, 'start_new_session': True})
        child.communicate.assert_called_once_with(timeout=5)

    def test_tool_success_still_drains_owned_group(self):
        child = unittest.mock.Mock(pid=12345, returncode=0)
        child.communicate.return_value = (b'ok', None)
        with patch.object(MODULE.subprocess, 'Popen', return_value=child), \
             patch.object(MODULE._png, 'stop_owned_process') as stop:
            self.assertEqual(MODULE.run_tool(['git', 'rev-parse', 'HEAD'], 5), b'ok')
            stop.assert_called_once_with(child)

    def test_interrupt_preserves_exit_after_owned_cleanup(self):
        child = unittest.mock.Mock(pid=12345)
        child.communicate.side_effect = SystemExit(143)
        with patch.object(MODULE.subprocess, 'Popen', return_value=child), \
             patch.object(MODULE._png, 'stop_owned_process') as stop:
            with self.assertRaises(SystemExit) as result:
                MODULE.run_tool(['git'], 5)
            self.assertEqual(result.exception.code, 143)
            stop.assert_called_once_with(child)


if __name__ == '__main__':
    unittest.main()

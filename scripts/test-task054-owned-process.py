#!/usr/bin/env python3
"""Prova reale del cleanup annidato, solo processi Python propri e PID temporanei."""
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import call, patch


HELPER_PATH = Path(__file__).with_name('run-task054-android-visual.py').resolve()
SPEC = importlib.util.spec_from_file_location('cmc_owned_process', HELPER_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

CHILD_SOURCE = '''\
import json
import os
from pathlib import Path
import signal
import sys

signal.signal(signal.SIGTERM, signal.SIG_IGN)
Path(sys.argv[1]).write_text(json.dumps({'pid': os.getpid(), 'pgid': os.getpgrp()}))
while True:
    signal.pause()
'''

NESTED_HELPER_SOURCE = '''\
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

spec = importlib.util.spec_from_file_location('cmc_nested_cleanup', sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
root = Path(sys.argv[2])
child = None

def interrupted(signum, _frame):
    global child
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    module.stop_owned_process(child)  # default term_grace5, child ignora TERM
    child_code = child.returncode
    child = None
    (root / 'completed.json').write_text(json.dumps({
        'received': signum, 'child_exit': child_code, 'cleanup': 'PASS'}))
    raise SystemExit(128 + signum)

signal.signal(signal.SIGTERM, interrupted)
signal.signal(signal.SIGINT, interrupted)
try:
    child = subprocess.Popen([sys.executable, str(root / 'child.py'),
        str(root / 'child-ready.json')], start_new_session=True,
        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    (root / 'helper-pids.json').write_text(json.dumps({
        'helper_pid': os.getpid(), 'helper_pgid': os.getpgrp(), 'child_pid': child.pid}))
    deadline = time.monotonic() + 5
    while not (root / 'child-ready.json').exists():
        if child.poll() is not None or time.monotonic() >= deadline:
            raise SystemExit(4)
        time.sleep(0.02)
    (root / 'helper-ready.json').write_text('{}')
    while True:
        signal.pause()
finally:
    if child is not None:
        module.stop_owned_process(child)
'''

LEADER_SOURCE = '''\
import json
import os
from pathlib import Path
import signal
import subprocess
import sys

root = Path(sys.argv[2])
helper = subprocess.Popen([sys.executable, str(root / 'nested-helper.py'),
    sys.argv[1], str(root)], stdin=subprocess.DEVNULL,
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
(root / 'leader-ready.json').write_text(json.dumps({
    'leader_pid': os.getpid(), 'leader_pgid': os.getpgrp(), 'helper_pid': helper.pid}))
while True:
    signal.pause()
'''


def wait_json(path, leader, timeout=5):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if leader.poll() is not None:
            raise AssertionError('leader terminato prima della readiness')
        try:
            value = json.loads(path.read_text())
            if isinstance(value, dict):
                return value
        except (OSError, ValueError):
            pass
        time.sleep(0.02)
    raise AssertionError('readiness del fixture non raggiunta entro il limite')


def stop_descendant_group(group):
    """Fallback del solo gruppo child dichiarato dall'helper creato nel test."""
    if not MODULE.owned_group_has_live_members(group):
        return
    os.killpg(group, signal.SIGKILL)
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        if not MODULE.owned_group_has_live_members(group):
            return
        time.sleep(0.02)
    raise AssertionError('cleanup del gruppo child proprio non concluso')


class OwnedNestedProcessTest(unittest.TestCase):
    def test_parent_waits_for_nested_owned_cleanup_and_preserves_leader_exit(self):
        leader = None
        child_group = None
        original_group = os.getpgrp()
        with tempfile.TemporaryDirectory(prefix='cmc-owned-nested-test-') as directory:
            root = Path(directory).resolve()
            (root / 'child.py').write_text(CHILD_SOURCE)
            (root / 'nested-helper.py').write_text(NESTED_HELPER_SOURCE)
            (root / 'leader.py').write_text(LEADER_SOURCE)
            try:
                leader = subprocess.Popen([sys.executable, str(root / 'leader.py'),
                    str(HELPER_PATH), str(root)], start_new_session=True,
                    stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL)
                outer = wait_json(root / 'leader-ready.json', leader)
                nested = wait_json(root / 'helper-pids.json', leader)
                child = wait_json(root / 'child-ready.json', leader)
                wait_json(root / 'helper-ready.json', leader)
                self.assertEqual(outer['leader_pid'], leader.pid)
                self.assertEqual(outer['leader_pgid'], leader.pid)
                self.assertEqual(outer['helper_pid'], nested['helper_pid'])
                self.assertEqual(nested['helper_pgid'], leader.pid)
                self.assertEqual(os.getpgid(nested['helper_pid']), leader.pid)
                self.assertIsInstance(nested['child_pid'], int)
                self.assertGreater(nested['child_pid'], 1)
                self.assertEqual(child['pid'], nested['child_pid'])
                self.assertEqual(child['pgid'], nested['child_pid'])
                self.assertEqual(os.getpgid(nested['child_pid']), nested['child_pid'])
                self.assertNotEqual(nested['child_pid'], leader.pid)
                self.assertNotEqual(nested['child_pid'], original_group)
                child_group = nested['child_pid']
                self.assertNotEqual(original_group, leader.pid)

                # Intercetta solo i segnali del parent: gli altri interpreti
                # eseguono davvero handler, TERM ignorato e cleanup inner5.
                original_killpg = os.killpg
                with patch.object(MODULE.os, 'killpg', wraps=original_killpg) as sent:
                    MODULE.stop_owned_process(leader, term_grace=20)
                self.assertEqual(leader.returncode, -signal.SIGTERM)
                self.assertEqual(sent.call_args_list,
                    [call(leader.pid, signal.SIGTERM)])
                completed = json.loads((root / 'completed.json').read_text())
                self.assertEqual(completed,
                    {'received': signal.SIGTERM, 'child_exit': -signal.SIGKILL,
                     'cleanup': 'PASS'})
                self.assertFalse(MODULE.owned_group_has_live_members(leader.pid))
                self.assertFalse(MODULE.owned_group_has_live_members(child_group))
                self.assertEqual(os.getpgrp(), original_group)
            finally:
                # Nomi e PID provengono esclusivamente dalle risorse del test.
                # Il helper può ancora finire il proprio cleanup se un assert fallisce.
                cleanup_failed = False
                try:
                    if leader is not None and (leader.poll() is None or
                            MODULE.owned_group_has_live_members(leader.pid)):
                        MODULE.stop_owned_process(leader, term_grace=20)
                except Exception:
                    cleanup_failed = True
                try:
                    if child_group is not None:
                        stop_descendant_group(child_group)
                except Exception:
                    cleanup_failed = True
                self.assertFalse(cleanup_failed, 'cleanup delle sole risorse proprie fallito')


if __name__ == '__main__':
    unittest.main()

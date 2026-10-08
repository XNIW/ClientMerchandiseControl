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
import threading
import time
from types import SimpleNamespace
import unittest
from unittest.mock import call, patch


HELPER_PATH = Path(__file__).with_name('run-task054-android-visual.py').resolve()
SPEC = importlib.util.spec_from_file_location('cmc_owned_process', HELPER_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
OS_SPEC = importlib.util.spec_from_file_location('cmc_os_cleanup_signal',
    HELPER_PATH.with_name('capture-task054-os-frame.py'))
OS_MODULE = importlib.util.module_from_spec(OS_SPEC)
OS_SPEC.loader.exec_module(OS_MODULE)
VISUAL_SOURCE = HELPER_PATH.with_name('test-task054-visual.sh').read_text().split(
    "<<'PYCODE'\n", 1)[1].rsplit('\nPYCODE', 1)[0].split(
    'signal.signal(signal.SIGTERM, interrupted)', 1)[0]

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
    def exercise_callsite(self, owner, leader_code, signum=None, trigger='during-cleanup'):
        """Processi reali; grace test ridotta, valori di produzione verificati."""
        previous = {sig: signal.getsignal(sig) for sig in (signal.SIGTERM, signal.SIGINT)}
        leaders, timers, received = [], [], []
        real_popen = subprocess.Popen
        real_mask, real_probe, real_killpg = signal.pthread_sigmask, subprocess.run, os.killpg
        previous_mask = real_mask(signal.SIG_BLOCK, [])
        probe_enabled, sent = [], []
        real_stop = (OS_MODULE.stop_owned_process if owner == 'os' else MODULE.stop_owned_process)
        real_fallback = (OS_MODULE._cleanup_module.finish_owned_cleanup_after_error
                         if owner == 'os' else MODULE.finish_owned_cleanup_after_error)
        with tempfile.TemporaryDirectory(prefix='cmc-owned-callsite-') as directory:
            root = Path(directory).resolve()
            ready = root / 'child.json'
            child_source = (
                'import json,os,signal,time;from pathlib import Path;'
                'signal.signal(signal.SIGTERM,signal.SIG_IGN);'
                f'Path({str(ready)!r}).write_text(json.dumps({{"pid":os.getpid(),"pgid":os.getpgrp()}}));'
                'time.sleep(60)')
            leader_source = (
                'import subprocess,sys,time;from pathlib import Path;'
                f'subprocess.Popen([sys.executable,"-c",{child_source!r}],'
                'stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);'
                f'p=Path({str(ready)!r});deadline=time.monotonic()+3\n'
                'while not p.exists() and time.monotonic()<deadline:time.sleep(.01)\n'
                f'sys.exit({leader_code})')
            command = [sys.executable, '-c', leader_source]

            def start(arguments, **kwargs):
                process = real_popen(arguments, **kwargs)
                if arguments == command:
                    self.assertTrue(kwargs['start_new_session'])
                    leaders.append(process)
                return process

            def stop(process, **kwargs):
                expected = {'term_grace': 20 if owner == 'visual' else 5}
                self.assertEqual(kwargs, {} if owner == 'os' else expected)
                self.assertTrue(ready.exists(), 'child pronto prima cleanup')
                child = json.loads(ready.read_text())
                self.assertEqual(child['pgid'], process.pid)
                self.assertNotEqual(process.pid, os.getpgrp())
                self.assertTrue(MODULE.owned_group_has_live_members(process.pid))
                probe_enabled.append(True)
                if trigger == 'pre-helper':
                    received.append(signum)
                    os.kill(os.getpid(), signum)
                if signum is not None and trigger == 'during-cleanup':
                    def send():
                        received.append(signum)
                        os.kill(os.getpid(), signum)
                    timer = threading.Timer(.1, send)
                    timers.append(timer)
                    timer.start()
                # Il limite ridotto appartiene solo al test. Il figlio IGNORETERM
                # rende osservabile il KILL vero senza attendere i 20s del driver.
                return real_stop(process, term_grace=.5 if trigger == 'during-cleanup'
                                 and signum is not None else .2)

            def fallback(process, error, **kwargs):
                if 'handlers' in kwargs:
                    # Entrata interrotta dentro il helper, dopo la grace test
                    # ridotta già verificata dal wrapper stop.
                    self.assertEqual(kwargs['term_grace'], .2)
                    self.assertEqual(set(kwargs['handlers']), set(previous))
                else:
                    self.assertEqual(kwargs, {} if owner == 'os' else {
                        'term_grace': 20 if owner == 'visual' else 5})
                return real_fallback(process, error, term_grace=.2,
                    handlers=kwargs.get('handlers'))

            def mask(how, signals):
                if trigger == 'pre-guard' and how == signal.SIG_BLOCK and not received:
                    received.append(signum)
                    os.kill(os.getpid(), signum)
                return real_mask(how, signals)

            def probe(arguments, *args, **kwargs):
                if probe_enabled and arguments == ['ps', '-A', '-o', 'pgid=', '-o', 'stat=']:
                    if trigger == 'malformed-probe':
                        return SimpleNamespace(returncode=0, stdout='unverifiable\n')
                    if trigger == 'timeout-probe':
                        raise subprocess.TimeoutExpired('ps', 2)
                return real_probe(arguments, *args, **kwargs)

            def killpg(group, sig):
                self.assertEqual(group, leaders[0].pid)
                self.assertNotEqual(group, os.getpgrp())
                sent.append(sig)
                return real_killpg(group, sig)

            try:
                if owner == 'visual':
                    namespace = {'cleanup_failed': False}
                    with patch('sys.argv', ['runner', '--device', 'owned-fixture']), \
                         patch.dict(os.environ, {'CMC_TASK054_SCRIPTS_DIR': str(HELPER_PATH.parent)}):
                        exec(compile(VISUAL_SOURCE, 'visual-owned-callsite', 'exec'), namespace)
                    namespace['cleanup_module'] = SimpleNamespace(
                        stop_owned_process=stop, Failure=MODULE.Failure,
                        finish_owned_cleanup_after_error=fallback)
                    handler = namespace['interrupted']
                    operation = lambda: namespace['run'](command, 3)
                elif owner == 'android':
                    runner = MODULE.AndroidVisualRunner(root)
                    handler = MODULE.interrupted
                    operation = lambda: runner.command(command, 3)
                else:
                    capture = OS_MODULE.OSFrameCapture(root, 'signal-focus', 'ios',
                        '11111111-1111-4111-8111-111111111111', {})
                    capture.receipt['frame_status'] = 'FAIL'
                    capture.capture = lambda: capture.command(command, 3, 'screen')
                    handler = OS_MODULE.interrupted
                    operation = capture.run
                if trigger == 'pre-caller':
                    def before_caller(_process):
                        received.append(signum)
                        os.kill(os.getpid(), signum)
                    if owner == 'android':
                        runner.stop_command = before_caller
                    else:
                        namespace['stop_command'] = before_caller
                for sig in previous:
                    signal.signal(sig, handler)
                target = OS_MODULE if owner == 'os' else MODULE
                fallback_target = OS_MODULE._cleanup_module if owner == 'os' else MODULE
                with patch.object(subprocess, 'Popen', side_effect=start), \
                     patch.object(target, 'stop_owned_process', side_effect=stop), \
                     patch.object(fallback_target, 'finish_owned_cleanup_after_error',
                                  side_effect=fallback), \
                     patch.object(signal, 'pthread_sigmask', side_effect=mask), \
                     patch.object(subprocess, 'run', side_effect=probe), \
                     patch.object(os, 'killpg', side_effect=killpg):
                    try:
                        result = operation()
                        code = result if owner == 'os' else 0
                    except (SystemExit, MODULE.Failure, OS_MODULE.Failure) as error:
                        code = error.code
                probe_failure = trigger in ('malformed-probe', 'timeout-probe')
                expected = leader_code or (128 + signum if signum is not None
                                          else 1 if probe_failure else 0)
                self.assertEqual(code, expected)
                self.assertEqual(len(leaders), 1)
                self.assertFalse(MODULE.owned_group_has_live_members(leaders[0].pid))
                self.assertEqual(real_mask(signal.SIG_BLOCK, []), previous_mask)
                self.assertEqual([sig for sig in sent if sig], [signal.SIGTERM, signal.SIGKILL])
                if signum is not None:
                    self.assertEqual(received, [signum])
                if owner == 'os':
                    receipt = json.loads(capture.receipt_path.read_text())
                    self.assertEqual(receipt['exit_code'], expected)
                    self.assertEqual(receipt['cleanup_status'], 'FAIL' if probe_failure else 'PASS')
                elif owner == 'android':
                    self.assertEqual(runner.cleanup_failed, probe_failure)
                else:
                    self.assertEqual(namespace['cleanup_failed'], probe_failure)
            finally:
                for timer in timers:
                    timer.cancel()
                    timer.join(timeout=1)
                    self.assertFalse(timer.is_alive())
                for sig, handler in previous.items():
                    signal.signal(sig, handler)
                real_mask(signal.SIG_SETMASK, previous_mask)
                for leader in leaders:
                    if MODULE.owned_group_has_live_members(leader.pid):
                        MODULE.stop_owned_process(leader, term_grace=.1)
                    leader.wait(timeout=2)

    def test_normal_exit_zero_and_seven_drain_owned_groups_at_every_callsite(self):
        for owner in ('android', 'visual', 'os'):
            for code in (0, 7):
                with self.subTest(owner=owner, code=code):
                    self.exercise_callsite(owner, code)

    def test_first_term_and_int_during_cleanup_are_deferred_until_quiescence(self):
        for owner in ('android', 'visual', 'os'):
            for signum in (signal.SIGTERM, signal.SIGINT):
                for code in (0, 7):
                    with self.subTest(owner=owner, signal=signum, code=code):
                        self.exercise_callsite(owner, code, signum)

    def test_term_and_int_before_helper_and_before_first_guard_still_drain_group(self):
        for owner in ('android', 'visual', 'os'):
            for trigger in ('pre-helper', 'pre-guard'):
                for signum in (signal.SIGTERM, signal.SIGINT):
                    for code in (0, 7):
                        with self.subTest(owner=owner, trigger=trigger, signal=signum, code=code):
                            self.exercise_callsite(owner, code, signum, trigger)

    def test_malformed_and_timeout_probes_still_kill_and_preserve_primary_failure(self):
        for owner in ('android', 'visual', 'os'):
            for trigger in ('malformed-probe', 'timeout-probe'):
                for code in (0, 7):
                    with self.subTest(owner=owner, trigger=trigger, code=code):
                        self.exercise_callsite(owner, code, trigger=trigger)

    def test_term_and_int_before_cleanup_wrapper_still_drain_owned_lifecycle(self):
        for owner in ('android', 'visual'):
            for signum in (signal.SIGTERM, signal.SIGINT):
                for code in (0, 7):
                    with self.subTest(owner=owner, signal=signum, code=code):
                        self.exercise_callsite(owner, code, signum, 'pre-caller')

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

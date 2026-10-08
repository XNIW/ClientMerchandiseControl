#!/usr/bin/env python3
"""Misure monotonic del trasporto esistente, senza nuovi timeout o segnali.

L'osservazione poll al timeout può effettuare il reap del leader già uscito;
questo limite è esplicito nella trace. Non stampa argv o output dei comandi.
"""
import contextlib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time


def operation(arguments):
    if not isinstance(arguments, (list, tuple)):
        return 'subprocess'
    if arguments[:2] == ['xcrun', 'simctl'] and len(arguments) > 2:
        action_index = 4 if arguments[2] == '--set' else 2
        action = arguments[action_index] if len(arguments) > action_index else None
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


@contextlib.contextmanager
def trace_processes(destination):
    path = Path(destination)
    # Nessuna operazione se la trace non è acquisibile esclusivamente.
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    original_popen, original_killpg = subprocess.Popen, os.killpg
    origin = time.monotonic_ns()
    sequence = 0
    trace_error = None
    owned_groups = set()

    with os.fdopen(descriptor, 'w', buffering=1) as stream:
        def emit(event, **metadata):
            nonlocal sequence, trace_error
            sequence += 1
            row = dict(sequence=sequence, monotonic_ns=time.monotonic_ns(),
                       elapsed_ns=time.monotonic_ns() - origin, event=event, **metadata)
            try:
                stream.write(json.dumps(row, sort_keys=True) + '\n')
            except OSError as error:
                # Un errore di evidence dopo spawn non deve perdere il handle
                # del processo: propagarlo solo dopo il finally del caller.
                trace_error = trace_error or error

        class MeasuredPopen(original_popen):
            def __init__(self, arguments, *args, **kwargs):
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

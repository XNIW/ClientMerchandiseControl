#!/usr/bin/env python3
"""Trasporto file terminale per il journal nativo; lifecycle Android invariato."""
import importlib.util
import json
from pathlib import Path
import re
import signal
import sys


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


ADDRESS = module('address_native_file_android_owner', 'run-address-journal-android.py')
Failure = ADDRESS.Failure
PHASE_TIMEOUT = 150
MAX_RECEIPT_BYTES = 8192


def receipt_relative_path(run_id, phase):
    if not re.fullmatch(r'[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}', run_id):
        raise Failure('journal-receipt-path', 2, 'run UUID non valido')
    if phase not in ('seed', 'recover'):
        raise Failure('journal-receipt-path', 2, 'fase non valida')
    return f'task054-address-journal-{run_id}/{phase}.json'


def validate_native_receipt(data, phase, run_id, process_id, seed_pid):
    receipt_relative_path(run_id, phase)
    if not isinstance(data, dict):
        raise Failure('journal-' + phase, 1, 'ricevuta non oggetto')
    if data.get('status') == 'FAIL':
        expected_keys = {'apiVersion', 'phase', 'runId', 'processId', 'status', 'errorType'}
        if (set(data) != expected_keys or data.get('apiVersion') != 'address-journal-native-evidence.v2'
                or data.get('phase') != phase or data.get('runId') != run_id
                or data.get('processId') != process_id
                or data.get('errorType') not in ('assertion', 'filesystem', 'unexpected')):
            raise Failure('journal-' + phase, 1, 'ricevuta failure non conforme')
        raise Failure('journal-' + phase, 1, 'fixture nativa segnala failure sanitizzata')
    return ADDRESS.validate_receipt(data, phase, run_id, process_id, seed_pid)


def write_exclusive(path, data):
    with path.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(data, indent=2) + '\n')


class AddressJournalFileRunner(ADDRESS.AddressJournalRunner):
    def drive(self, phase, process_id, seed_pid):
        # Il nome conserva l'interfaccia lifecycle esistente. Nessun drive/VM,
        # install, avvio o scrittura nel sandbox è eseguito da questo metodo.
        self.phase = 'journal-' + phase
        relative = 'files/' + receipt_relative_path(self.run_id, phase)
        accepted = []

        def accept(output):
            if len(output.encode('utf-8')) > MAX_RECEIPT_BYTES:
                raise Failure(self.phase, 1, 'ricevuta troppo grande')
            try:
                data = json.loads(output)
            except ValueError:
                return False
            accepted.append(validate_native_receipt(
                data, phase, self.run_id, process_id, seed_pid))
            return True

        self.wait_ready('journal-' + phase + '-terminal-receipt', PHASE_TIMEOUT,
            [str(self.adb), '-s', self.serial, 'shell', 'run-as', ADDRESS.PACKAGE,
             'cat', relative], accept)
        _, current = self.device(['shell', 'pidof', ADDRESS.PACKAGE])
        if current != str(process_id):
            raise Failure(self.phase, 1, 'processo fixture cambiato durante la fase')
        write_exclusive(self.output / (phase + '.json'), accepted[0])
        self.results[phase] = accepted[0]
        self.results['receipt_transport'] = 'app_support_run_as_terminal_sdk'


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, ADDRESS.OWNED.interrupted)
    signal.signal(signal.SIGINT, ADDRESS.OWNED.interrupted)
    raise SystemExit(AddressJournalFileRunner(Path(__file__).resolve().parent.parent).run())

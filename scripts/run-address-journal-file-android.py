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
NATIVE_ERROR_TYPES = ('assertion', 'filesystem', 'unexpected')
NATIVE_FAILURE_ORIGINS = ('body', 'terminal_gate')
NATIVE_FAILURE_CHECKPOINTS = ('recover_marker', 'recover_process',
    'restored_identity', 'restored_payload', 'cleared_readback')


def valid_terminal_gate_mask(value):
    # Bit64 (Invoker assente) conserva il fail-closed bit8; mai un esito positivo.
    return (type(value) is int and 1 <= value <= 127
        and (not value & 64 or bool(value & 8)))


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
        # V2/V3 storiche restano esatte. V4 aggiunge un checkpoint nullable:
        # solo una assertion body/recover puo attribuire una delle cinque verifiche.
        legacy_failure = (set(data) == expected_keys
            and data.get('apiVersion') == 'address-journal-native-evidence.v2')
        origin_failure = (set(data) == expected_keys | {'failureOrigin'}
            and data.get('apiVersion') == 'address-journal-native-evidence.v3'
            and data.get('failureOrigin') in NATIVE_FAILURE_ORIGINS
            and (data['failureOrigin'] != 'terminal_gate' or data.get('errorType') == 'assertion'))
        checkpoint = data.get('failureCheckpoint')
        checkpoint_failure = (set(data) == expected_keys | {'failureOrigin', 'failureCheckpoint'}
            and data.get('apiVersion') == 'address-journal-native-evidence.v4'
            and data.get('failureOrigin') in NATIVE_FAILURE_ORIGINS
            and (data['failureOrigin'] != 'terminal_gate' or data.get('errorType') == 'assertion')
            and (checkpoint is None or (checkpoint in NATIVE_FAILURE_CHECKPOINTS
                and data.get('failureOrigin') == 'body' and phase == 'recover'
                and data.get('errorType') == 'assertion')))
        terminal_gate_mask = data.get('terminalGateMask')
        terminal_mask_failure = (set(data) == expected_keys | {
                'failureOrigin', 'failureCheckpoint', 'terminalGateMask'}
            and data.get('apiVersion') == 'address-journal-native-evidence.v5'
            and data.get('failureOrigin') in NATIVE_FAILURE_ORIGINS
            and (data['failureOrigin'] != 'terminal_gate' or data.get('errorType') == 'assertion')
            and (checkpoint is None or (checkpoint in NATIVE_FAILURE_CHECKPOINTS
                and data.get('failureOrigin') == 'body' and phase == 'recover'
                and data.get('errorType') == 'assertion'))
            and ((data['failureOrigin'] == 'body' and terminal_gate_mask is None)
                or (data['failureOrigin'] == 'terminal_gate'
                    and valid_terminal_gate_mask(terminal_gate_mask))))
        if (not (legacy_failure or origin_failure or checkpoint_failure or terminal_mask_failure)
                or data.get('phase') != phase or data.get('runId') != run_id
                or data.get('processId') != process_id
                or data.get('errorType') not in NATIVE_ERROR_TYPES):
            raise Failure('journal-' + phase, 1, 'ricevuta failure non conforme')
        failure = Failure('journal-' + phase, 1, 'fixture nativa segnala failure sanitizzata')
        # Solo enum gia validati; mai payload, messaggi, stack o log nativi.
        failure.native_error_type = data['errorType']
        if origin_failure or checkpoint_failure or terminal_mask_failure:
            failure.native_failure_origin = data['failureOrigin']
        if (checkpoint_failure or terminal_mask_failure) and checkpoint is not None:
            failure.native_failure_checkpoint = checkpoint
        if terminal_mask_failure and terminal_gate_mask is not None:
            failure.native_terminal_gate_mask = terminal_gate_mask
        raise failure
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

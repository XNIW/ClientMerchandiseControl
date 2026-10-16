#!/usr/bin/env python3
"""Trasporto file terminale del journal Keychain; ownership/lifecycle invariati."""
import argparse
import importlib.util
import json
from pathlib import Path
import signal
import time


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


ADDRESS = module('address_native_file_ios_owner', 'run-address-journal-ios.py')
FILE = module('address_native_file_ios_contract', 'run-address-journal-file-android.py')


class IosAddressJournalFileRunner(ADDRESS.IosJournalRunner):
    def drive(self, phase, process_id, seed_pid, logs):
        self.phase = 'journal-' + phase
        try:
            relative = FILE.receipt_relative_path(self.run_id, phase)
            path = self.data / 'Library' / 'Application Support' / relative
            deadline = time.monotonic() + FILE.PHASE_TIMEOUT
            while time.monotonic() < deadline:
                self.attest_pid(process_id)
                if path.is_file():
                    if path.is_symlink() or self.data.resolve() not in path.resolve().parents:
                        raise ADDRESS.Failure(self.phase, 1, 'ricevuta fuori dal container proprio')
                    if path.stat().st_size > FILE.MAX_RECEIPT_BYTES:
                        raise ADDRESS.Failure(self.phase, 1, 'ricevuta troppo grande')
                    try:
                        data = json.loads(path.read_text(encoding='utf-8'))
                    except ValueError:
                        data = None
                    if data is not None:
                        accepted = FILE.validate_native_receipt(
                            data, phase, self.run_id, process_id, seed_pid)
                        self.attest_pid(process_id)
                        FILE.write_exclusive(self.output / (phase + '.json'), accepted)
                        self.results[phase] = accepted
                        self.results['receipt_transport'] = 'owned_app_support_terminal_sdk'
                        return
                time.sleep(min(0.25, max(0, deadline - time.monotonic())))
            raise ADDRESS.Failure(self.phase, 124, 'ricevuta journal non pubblicata entro150s')
        except FILE.Failure as error:
            native_error_type = getattr(error, 'native_error_type', None)
            if native_error_type in FILE.NATIVE_ERROR_TYPES:
                self.diagnostics.setdefault(phase, {})['native_terminal_error_type'] = native_error_type
            # I moduli ereditati hanno classi Failure distinte: il run() base
            # deve ricevere la propria classe per conservare exit/cleanup/receipt.
            raise ADDRESS.Failure(self.phase, error.code, str(error)) from None


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--owner-receipt', required=True)
    options = parser.parse_args()
    signal.signal(signal.SIGTERM, ADDRESS.ANDROID.OWNED.interrupted)
    signal.signal(signal.SIGINT, ADDRESS.ANDROID.OWNED.interrupted)
    raise SystemExit(IosAddressJournalFileRunner(Path(__file__).resolve().parent.parent,
        options.owner_receipt).run())

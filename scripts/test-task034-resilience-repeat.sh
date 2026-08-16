#!/usr/bin/env bash
set -euo pipefail

cmc_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_repo_root="$(cd -- "${cmc_script_dir}/.." && pwd)"
# shellcheck source=resolve-flutter.sh
source "${cmc_script_dir}/resolve-flutter.sh"

cmc_repeat_count="${CMC_TASK034_REPEAT_COUNT:-5}"
if [[ ! "${cmc_repeat_count}" =~ ^[0-9]+$ ]] ||
  ((cmc_repeat_count < 1 || cmc_repeat_count > 50)); then
  printf 'CMC_TASK034_REPEAT_COUNT deve essere compreso tra 1 e 50.\n' >&2
  exit 2
fi

cmc_name_pattern='doppio tap condivide un solo launch|cambio categoria cancella e ignora|doppio tap account produce una sola mutation|doppio tap con richiesta attiva|doppio tap serializzato crea una sola cancellazione|terminal snapshot cannot be overwritten|logout durante fallback|cambio account durante fallback|dispose durante fallback|dispose durante logout con unsubscribe asincrono|cambio account con unsubscribe asincrono|dispose durante close con unsubscribe asincrono|dispose durante unauthorized asincrono'

cd -- "${cmc_repo_root}"
for ((cmc_iteration = 1; cmc_iteration <= cmc_repeat_count; cmc_iteration++)); do
  flutter test \
    --reporter=compact \
    --concurrency=1 \
    --name "${cmc_name_pattern}" \
    test/features/auth/application/auth_controller_test.dart \
    test/features/catalog/application/catalog_controller_test.dart \
    test/features/cart/application/cart_controller_test.dart \
    test/features/checkout/application/checkout_controller_test.dart \
    test/features/orders/application/customer_order_controller_test.dart \
    test/features/delivery_tracking/delivery_tracking_controller_test.dart
done

printf 'TASK-034 resilience repeat: %s iterazioni, 13 race per iterazione, PASS.\n' \
  "${cmc_repeat_count}"

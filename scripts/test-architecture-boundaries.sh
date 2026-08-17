#!/usr/bin/env bash
set -euo pipefail

cmc_fixture_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_fixture_repo_root="$(git -C "${cmc_fixture_script_dir}" rev-parse --show-toplevel)"
cmc_fixture_validator="${cmc_fixture_script_dir}/check-architecture-boundaries.sh"
cmc_fixture_tmp_parent="${TMPDIR:-/tmp}"
cmc_fixture_tmp_parent="${cmc_fixture_tmp_parent%/}"
cmc_fixture_root="$(
  mktemp -d "${cmc_fixture_tmp_parent}/cmc-arch-fixtures.XXXXXX"
)"
cmc_fixture_total=0
cmc_fixture_rejected=0

cmc_fixture_cleanup() {
  case "${cmc_fixture_root}" in
    "${cmc_fixture_tmp_parent}"/cmc-arch-fixtures.*)
      rm -rf -- "${cmc_fixture_root}"
      ;;
    *)
      printf 'Cleanup fixture rifiutato per path inatteso.\n' >&2
      ;;
  esac
}

trap cmc_fixture_cleanup EXIT

cmc_fixture_prepare() {
  local cmc_fixture_name="$1"
  local cmc_fixture_path="${cmc_fixture_root}/${cmc_fixture_name}"

  mkdir -p "${cmc_fixture_path}/docs/TASKS" \
    "${cmc_fixture_path}/.dart_tool" \
    "${cmc_fixture_path}/lib/core" \
    "${cmc_fixture_path}/lib/features"
  cp "${cmc_fixture_repo_root}/.dart_tool/package_config.json" \
    "${cmc_fixture_path}/.dart_tool/package_config.json"
  cp "${cmc_fixture_repo_root}/pubspec.yaml" \
    "${cmc_fixture_path}/pubspec.yaml"
  cp -R "${cmc_fixture_repo_root}/docs/ARCHITECTURE" \
    "${cmc_fixture_path}/docs/"
  cp -R "${cmc_fixture_repo_root}/docs/DECISIONS" \
    "${cmc_fixture_path}/docs/"
  cp "${cmc_fixture_repo_root}/docs/MASTER-PLAN.md" \
    "${cmc_fixture_path}/docs/MASTER-PLAN.md"
  cp "${cmc_fixture_repo_root}/docs/QUALITY-GATES.md" \
    "${cmc_fixture_path}/docs/QUALITY-GATES.md"
  cp \
    "${cmc_fixture_repo_root}/docs/TASKS/TASK-002-product-scope-branding-design-system.md" \
    "${cmc_fixture_path}/docs/TASKS/TASK-002-product-scope-branding-design-system.md"
  cp -R "${cmc_fixture_repo_root}/lib/core/config" \
    "${cmc_fixture_path}/lib/core/"
  cp -R "${cmc_fixture_repo_root}/lib/features/storefront" \
    "${cmc_fixture_path}/lib/features/"
  cp -R "${cmc_fixture_repo_root}/lib/features/home" \
    "${cmc_fixture_path}/lib/features/"

  printf '%s\n' "${cmc_fixture_path}"
}

cmc_fixture_replace_literal() {
  local cmc_fixture_file="$1"
  local cmc_fixture_old="$2"
  local cmc_fixture_new="$3"
  local cmc_fixture_output="${cmc_fixture_file}.tmp"

  if ! grep -Fq -- "${cmc_fixture_old}" "${cmc_fixture_file}"; then
    printf 'Fixture non preparabile: literal sorgente assente.\n' >&2
    exit 1
  fi

  sed "s#${cmc_fixture_old}#${cmc_fixture_new}#" \
    "${cmc_fixture_file}" >"${cmc_fixture_output}"
  if cmp -s "${cmc_fixture_file}" "${cmc_fixture_output}"; then
    printf 'Fixture non preparabile: mutazione inefficace.\n' >&2
    exit 1
  fi
  mv "${cmc_fixture_output}" "${cmc_fixture_file}"
}

cmc_fixture_expect_rejection() {
  local cmc_fixture_path="$1"

  cmc_fixture_total=$((cmc_fixture_total + 1))
  if CMC_ARCH_REPO_ROOT="${cmc_fixture_path}" \
    bash "${cmc_fixture_validator}" >/dev/null 2>&1; then
    printf 'Fixture negativa accettata inaspettatamente: %s\n' \
      "${cmc_fixture_path##*/}" >&2
  else
    cmc_fixture_rejected=$((cmc_fixture_rejected + 1))
  fi
}

cmc_fixture_expect_rejection_code() {
  local cmc_fixture_path="$1"
  local cmc_fixture_expected="$2"
  local cmc_fixture_log="${cmc_fixture_root}/${cmc_fixture_path##*/}.log"

  cmc_fixture_total=$((cmc_fixture_total + 1))
  if CMC_ARCH_REPO_ROOT="${cmc_fixture_path}" \
    bash "${cmc_fixture_validator}" >"${cmc_fixture_log}" 2>&1; then
    printf 'Fixture negativa accettata inaspettatamente: %s\n' \
      "${cmc_fixture_path##*/}" >&2
    return
  fi
  if ! grep -Fq -- "APP_CONFIG_BINDING_BLOCKED: ${cmc_fixture_expected}" \
    "${cmc_fixture_log}"; then
    printf 'Fixture negativa fallita per ragione inattesa: %s\n' \
      "${cmc_fixture_path##*/}" >&2
    grep -E 'APP_CONFIG_BINDING_BLOCKED: [A-Z0-9_]+' \
      "${cmc_fixture_log}" >&2 || true
    return
  fi
  cmc_fixture_rejected=$((cmc_fixture_rejected + 1))
}

cmc_fixture_require_analyzer_clean() {
  local cmc_fixture_path="$1"
  shift

  dart format "$@" >/dev/null
  dart format --output=none --set-exit-if-changed "$@" >/dev/null
  (
    cd "${cmc_fixture_path}"
    dart analyze --fatal-infos --fatal-warnings "$@"
  )
}

bash "${cmc_fixture_validator}"

cmc_fixture_owner_path="$(cmc_fixture_prepare invalid-business-owner)"
cmc_fixture_replace_literal \
  "${cmc_fixture_owner_path}/docs/ARCHITECTURE/STOREFRONT-DATA-BOUNDARY.md" \
  "Shop owner/manager o ruolo commerciale Admin autorizzato" \
  "Admin Console"
cmc_fixture_expect_rejection "${cmc_fixture_owner_path}"

cmc_fixture_task012_path="$(cmc_fixture_prepare invalid-task012-scope)"
cmc_fixture_replace_literal \
  "${cmc_fixture_task012_path}/docs/DECISIONS/ADR-008-semantic-design-system.md" \
  "guest/data-safe" \
  "data-backed"
cmc_fixture_expect_rejection "${cmc_fixture_task012_path}"

cmc_fixture_task002_path="$(cmc_fixture_prepare invalid-task002-decision)"
cmc_fixture_replace_literal \
  "${cmc_fixture_task002_path}/docs/TASKS/TASK-002-product-scope-branding-design-system.md" \
  "TASK-012 resta owner della shell guest/data-safe" \
  "TASK-012 resta owner della shell data-backed"
cmc_fixture_expect_rejection "${cmc_fixture_task002_path}"

cmc_fixture_dag_path="$(cmc_fixture_prepare duplicate-dag-row)"
cmc_fixture_dag_file="${cmc_fixture_dag_path}/docs/DECISIONS/ADR-009-parallel-catalog-authentication-workstreams.md"
if ! grep -Fq -- "| TASK-005 | TASK-003, TASK-004 |" "${cmc_fixture_dag_file}"; then
  printf 'Fixture DAG non preparabile: riga sorgente assente.\n' >&2
  exit 1
fi
awk '
  {
    print
  }
  $0 == "| TASK-005 | TASK-003, TASK-004 |" {
    print "| TASK-005 | TASK-004 |"
  }
' "${cmc_fixture_dag_file}" >"${cmc_fixture_dag_file}.tmp"
mv "${cmc_fixture_dag_file}.tmp" "${cmc_fixture_dag_file}"
cmc_fixture_expect_rejection "${cmc_fixture_dag_path}"

cmc_fixture_quality_path="$(cmc_fixture_prepare invalid-quality-cardinality)"
cmc_fixture_replace_literal \
  "${cmc_fixture_quality_path}/docs/QUALITY-GATES.md" \
  "decision owner business non ambigui; elenca separatamente i writer, projector e" \
  "un solo decision owner, writer, projector e"
cmc_fixture_expect_rejection "${cmc_fixture_quality_path}"

cmc_fixture_direct_table_path="$(cmc_fixture_prepare invalid-storefront-direct-table)"
cmc_fixture_replace_literal \
  "${cmc_fixture_direct_table_path}/lib/features/storefront/data/http_storefront_rpc_invoker.dart" \
  "_origin.resolve('/rest/v1/rpc/\$function')" \
  "_origin.resolve('/rest/v1/inventory_products')"
cmc_fixture_expect_rejection "${cmc_fixture_direct_table_path}"

cmc_fixture_storage_path="$(cmc_fixture_prepare invalid-storefront-storage-access)"
cmc_fixture_replace_literal \
  "${cmc_fixture_storage_path}/lib/features/storefront/data/http_storefront_rpc_invoker.dart" \
  "_origin.resolve('/rest/v1/rpc/\$function')" \
  "_origin.resolve('/storage/v1/object/list/product-images')"
cmc_fixture_expect_rejection "${cmc_fixture_storage_path}"

cmc_fixture_shop_slug_path="$(cmc_fixture_prepare invalid-storefront-shop-slug-key)"
cmc_fixture_replace_literal \
  "${cmc_fixture_shop_slug_path}/lib/core/config/app_config.dart" \
  "'STOREFRONT_SHOP_SLUG'," \
  "'ATTACKER_SHOP_SLUG',"
cmc_fixture_expect_rejection "${cmc_fixture_shop_slug_path}"

cmc_fixture_shop_slug_comment_path="$(
  cmc_fixture_prepare invalid-storefront-shop-slug-comment-decoy
)"
cmc_fixture_shop_slug_comment_file="${cmc_fixture_shop_slug_comment_path}/lib/core/config/app_config.dart"
cmc_fixture_replace_literal \
  "${cmc_fixture_shop_slug_comment_file}" \
  "'STOREFRONT_SHOP_SLUG'," \
  "'ATTACKER_SHOP_SLUG',"
awk '
  {
    print
    if ($0 == "class AppConfig {") {
      print "  /* outer /* nested */"
      print "  static const _compiledStorefrontShopSlug ="
      print "      String.fromEnvironment(\047STOREFRONT_SHOP_SLUG\047); */"
    }
  }
' "${cmc_fixture_shop_slug_comment_file}" \
  >"${cmc_fixture_shop_slug_comment_file}.tmp"
mv "${cmc_fixture_shop_slug_comment_file}.tmp" \
  "${cmc_fixture_shop_slug_comment_file}"
cmc_fixture_expect_rejection "${cmc_fixture_shop_slug_comment_path}"

cmc_fixture_shop_slug_string_path="$(
  cmc_fixture_prepare invalid-storefront-shop-slug-string-decoy
)"
cmc_fixture_shop_slug_string_file="${cmc_fixture_shop_slug_string_path}/lib/core/config/app_config.dart"
cmc_fixture_replace_literal \
  "${cmc_fixture_shop_slug_string_file}" \
  "'STOREFRONT_SHOP_SLUG'," \
  "'ATTACKER_SHOP_SLUG',"
awk '
  {
    print
    if ($0 == "class AppConfig {") {
      print "  static const _storefrontBindingDecoy = r\042\042\042"
      print "  static const _compiledStorefrontShopSlug ="
      print "      String.fromEnvironment(\047STOREFRONT_SHOP_SLUG\047);"
      print "  \042\042\042;"
    }
  }
' "${cmc_fixture_shop_slug_string_file}" \
  >"${cmc_fixture_shop_slug_string_file}.tmp"
mv "${cmc_fixture_shop_slug_string_file}.tmp" \
  "${cmc_fixture_shop_slug_string_file}"
cmc_fixture_expect_rejection "${cmc_fixture_shop_slug_string_path}"

cmc_fixture_shop_slug_class_path="$(
  cmc_fixture_prepare invalid-storefront-shop-slug-class-decoy
)"
cmc_fixture_shop_slug_class_file="${cmc_fixture_shop_slug_class_path}/lib/core/config/app_config.dart"
perl -0pi -e '
  s{  static const _compiledStorefrontShopSlug = String\.fromEnvironment\(\n    .STOREFRONT_SHOP_SLUG.,\n  \);}{  static const _compiledStorefrontShopSlugRuntime = String.fromEnvironment(\n    \x27ATTACKER_SHOP_SLUG\x27,\n  );\n  static String get _compiledStorefrontShopSlug =>\n      _compiledStorefrontShopSlugRuntime;}
' "${cmc_fixture_shop_slug_class_file}"
if ! grep -Fq -- "'ATTACKER_SHOP_SLUG'," \
  "${cmc_fixture_shop_slug_class_file}"; then
  printf 'Fixture class decoy non preparabile: mutation assente.\n' >&2
  exit 1
fi
{
  printf '%s\n' \
    'class StorefrontBindingDecoy {' \
    '  static const _compiledStorefrontShopSlug =' \
    "      String.fromEnvironment('STOREFRONT_SHOP_SLUG');" \
    '  static String get value => _compiledStorefrontShopSlug;' \
    '}' \
    ''
  cat "${cmc_fixture_shop_slug_class_file}"
} >"${cmc_fixture_shop_slug_class_file}.tmp"
mv "${cmc_fixture_shop_slug_class_file}.tmp" \
  "${cmc_fixture_shop_slug_class_file}"
cmc_fixture_expect_rejection "${cmc_fixture_shop_slug_class_path}"

cmc_fixture_shop_slug_shadow_path="$(
  cmc_fixture_prepare invalid-storefront-shop-slug-parameter-shadow
)"
cmc_fixture_shop_slug_shadow_file="${cmc_fixture_shop_slug_shadow_path}/lib/core/config/app_config.dart"
perl -0pi -e '
  s{factory AppConfig\.fromEnvironment\(\) \{}{factory AppConfig.fromEnvironment([\n    String _compiledStorefrontShopSlug = const String.fromEnvironment(\n      \x27ATTACKER_SHOP_SLUG\x27,\n    ),\n  ]) \{}
' "${cmc_fixture_shop_slug_shadow_file}"
if ! grep -Fq -- "'ATTACKER_SHOP_SLUG'," \
  "${cmc_fixture_shop_slug_shadow_file}"; then
  printf 'Fixture parameter shadow non preparabile: mutation assente.\n' >&2
  exit 1
fi
cmc_fixture_expect_rejection "${cmc_fixture_shop_slug_shadow_path}"

cmc_fixture_shop_slug_constructor_path="$(
  cmc_fixture_prepare invalid-storefront-shop-slug-constructor-identity
)"
cmc_fixture_shop_slug_constructor_file="${cmc_fixture_shop_slug_constructor_path}/lib/core/config/app_config.dart"
cmc_fixture_shop_slug_decoy_file="${cmc_fixture_shop_slug_constructor_path}/lib/core/config/storefront_string_decoy.dart"
{
  printf '%s\n' "import 'storefront_string_decoy.dart' as decoy;"
  cat "${cmc_fixture_shop_slug_constructor_file}"
} >"${cmc_fixture_shop_slug_constructor_file}.tmp"
mv "${cmc_fixture_shop_slug_constructor_file}.tmp" \
  "${cmc_fixture_shop_slug_constructor_file}"
perl -0pi -e '
  s{  static const _compiledStorefrontShopSlug = String\.fromEnvironment\(\n    \x27STOREFRONT_SHOP_SLUG\x27,\n  \);}{  static const _compiledStorefrontShopSlug = decoy.String.fromEnvironment(\n    \x27STOREFRONT_SHOP_SLUG\x27,\n  );}
' "${cmc_fixture_shop_slug_constructor_file}"
printf '%s\n' \
  "import 'dart:core' as core;" \
  '' \
  'extension type const String(core.String value)' \
  '    implements core.String {' \
  '  const String.fromEnvironment(' \
  '    core.String _,' \
  '  ) : this(const core.String.fromEnvironment(' \
  "          'ATTACKER_SHOP_SLUG'," \
  '        ));' \
  '}' >"${cmc_fixture_shop_slug_decoy_file}"
cmc_fixture_require_analyzer_clean \
  "${cmc_fixture_shop_slug_constructor_path}" \
  "${cmc_fixture_shop_slug_constructor_file}" \
  "${cmc_fixture_shop_slug_decoy_file}"
cmc_fixture_expect_rejection_code \
  "${cmc_fixture_shop_slug_constructor_path}" \
  COMPILED_BINDING_STRUCTURE_INVALID

cmc_fixture_shop_slug_consumer_path="$(
  cmc_fixture_prepare invalid-storefront-shop-slug-consumer-decoy
)"
cmc_fixture_shop_slug_consumer_file="${cmc_fixture_shop_slug_consumer_path}/lib/core/config/app_config.dart"
perl -0pi -e '
  s{    final config = AppConfig\.fromValues\(.*?\n    \);\n    if \(config\.environment}{    final config = Function.apply(\n      AppConfig.fromValues,\n      const [],\n      {\n        #appEnvironment: _compiledAppEnvironment,\n        #supabaseUrl: _compiledSupabaseUrl,\n        #supabasePublishableKey: _compiledSupabasePublishableKey,\n        #authRedirectUri: _compiledAuthRedirectUri,\n        #googleAuthEnabled: _compiledGoogleAuthEnabled,\n        #storefrontShopSlug:\n            const String.fromEnvironment(\x27ATTACKER_SHOP_SLUG\x27),\n        #releaseConfigSha256: _compiledReleaseConfigSha256,\n      },\n    ) as AppConfig;\n    if (config.environment}s
' "${cmc_fixture_shop_slug_consumer_file}"
if ! grep -Fq -- "'ATTACKER_SHOP_SLUG'" \
  "${cmc_fixture_shop_slug_consumer_file}"; then
  printf 'Fixture consumer decoy non preparabile: mutation assente.\n' >&2
  exit 1
fi
cmc_fixture_require_analyzer_clean \
  "${cmc_fixture_shop_slug_consumer_path}" \
  "${cmc_fixture_shop_slug_consumer_file}"
cmc_fixture_expect_rejection_code \
  "${cmc_fixture_shop_slug_consumer_path}" \
  COMPILED_BINDING_CONSUMER_INVALID

cmc_fixture_config_binding_path="$(
  cmc_fixture_prepare invalid-full-config-binding
)"
cmc_fixture_config_binding_file="${cmc_fixture_config_binding_path}/lib/core/config/app_config.dart"
perl -0pi -e '
  s{  static const _compiledSupabaseUrl = String\.fromEnvironment\(\x27SUPABASE_URL\x27\);}{  static const _compiledSupabaseUrl = String.fromEnvironment(\x27SUPABASE_URL\x27);\n  static const _compiledAttackerSupabaseUrl =\n      String.fromEnvironment(\x27ATTACKER_SUPABASE_URL\x27);};
  s{supabaseUrl: _compiledSupabaseUrl,}{supabaseUrl: _compiledAttackerSupabaseUrl,};
' "${cmc_fixture_config_binding_file}"
if ! grep -Fq -- "'ATTACKER_SUPABASE_URL'" \
  "${cmc_fixture_config_binding_file}"; then
  printf 'Fixture full config binding non preparabile: mutation assente.\n' >&2
  exit 1
fi
cmc_fixture_require_analyzer_clean \
  "${cmc_fixture_config_binding_path}" \
  "${cmc_fixture_config_binding_file}"
cmc_fixture_expect_rejection_code \
  "${cmc_fixture_config_binding_path}" \
  COMPILED_BINDING_CONSUMER_INVALID

cmc_fixture_control_flow_path="$(
  cmc_fixture_prepare invalid-production-control-flow
)"
cmc_fixture_control_flow_file="${cmc_fixture_control_flow_path}/lib/core/config/app_config.dart"
perl -0pi -e '
  s{    if \(config\.environment != AppEnvironment\.production\) \{\n      return config;\n    \}}{    if (config.environment == AppEnvironment.production ||\n        config.environment != AppEnvironment.production) {\n      return config;\n    }}
' "${cmc_fixture_control_flow_file}"
if ! grep -Fq -- 'config.environment == AppEnvironment.production ||' \
  "${cmc_fixture_control_flow_file}"; then
  printf 'Fixture control flow non preparabile: mutation assente.\n' >&2
  exit 1
fi
cmc_fixture_require_analyzer_clean \
  "${cmc_fixture_control_flow_path}" \
  "${cmc_fixture_control_flow_file}"
cmc_fixture_expect_rejection_code \
  "${cmc_fixture_control_flow_path}" \
  COMPILED_BINDING_CONSUMER_INVALID

cmc_fixture_attestation_library_path="$(
  cmc_fixture_prepare invalid-attestation-library-identity
)"
cmc_fixture_attestation_library_file="${cmc_fixture_attestation_library_path}/lib/core/config/app_config.dart"
cmc_fixture_attestation_decoy_dir="${cmc_fixture_attestation_library_path}/lib/evil/core/config"
mkdir -p "${cmc_fixture_attestation_decoy_dir}"
cp "${cmc_fixture_attestation_library_path}/lib/core/config/release_config_attestation.dart" \
  "${cmc_fixture_attestation_decoy_dir}/release_config_attestation.dart"
cmc_fixture_replace_literal \
  "${cmc_fixture_attestation_library_file}" \
  "import 'release_config_attestation.dart';" \
  "import '../../evil/core/config/release_config_attestation.dart';"
cmc_fixture_require_analyzer_clean \
  "${cmc_fixture_attestation_library_path}" \
  "${cmc_fixture_attestation_library_file}" \
  "${cmc_fixture_attestation_decoy_dir}/release_config_attestation.dart"
cmc_fixture_expect_rejection_code \
  "${cmc_fixture_attestation_library_path}" \
  COMPILED_BINDING_STRUCTURE_INVALID

if [[ "${cmc_fixture_rejected}" -ne "${cmc_fixture_total}" ]]; then
  printf 'Fixture negative respinte: %d/%d.\n' \
    "${cmc_fixture_rejected}" "${cmc_fixture_total}" >&2
  exit 1
fi

printf 'Fixture negative architetturali respinte: %d/%d.\n' \
  "${cmc_fixture_rejected}" "${cmc_fixture_total}"

#!/usr/bin/env bash
set -euo pipefail

cmc_security_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_security_default_root="$(git -C "${cmc_security_script_dir}" rev-parse --show-toplevel)"
cmc_security_repo_root="${CMC_SECURITY_REPO_ROOT:-${cmc_security_default_root}}"
cmc_security_violation_count=0
cmc_security_tracked_count=0
cmc_security_artifact_file_count=0
cmc_security_artifacts=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --artifact)
      shift
      if [[ "$#" -eq 0 ]]; then
        printf 'Security scan: valore mancante per --artifact.\n' >&2
        exit 1
      fi
      cmc_security_artifacts+=("$1")
      ;;
    *)
      printf 'Security scan: argomento non supportato.\n' >&2
      exit 1
      ;;
  esac
  shift
done

if ! git -C "${cmc_security_repo_root}" rev-parse --is-inside-work-tree \
  >/dev/null 2>&1; then
  printf 'Security scan non eseguibile: repository Git non valido.\n' >&2
  exit 1
fi
if ! command -v openssl >/dev/null 2>&1 || \
  ! command -v perl >/dev/null 2>&1 || \
  ! command -v tr >/dev/null 2>&1 || \
  ! perl -MJSON::PP -MDigest::SHA -e 1 >/dev/null 2>&1; then
  printf 'Security scan non eseguibile: dipendenza di decode assente.\n' >&2
  exit 1
fi

cmc_security_tmp_parent="${TMPDIR:-/tmp}"
cmc_security_tmp_parent="${cmc_security_tmp_parent%/}"
cmc_security_tmp_root="$(
  mktemp -d "${cmc_security_tmp_parent}/cmc-client-security.XXXXXX"
)"
cmc_security_cleanup() {
  case "${cmc_security_tmp_root}" in
    "${cmc_security_tmp_parent}"/cmc-client-security.*)
      rm -rf -- "${cmc_security_tmp_root}"
      ;;
    *)
      printf 'Cleanup security rifiutato per path inatteso.\n' >&2
      ;;
  esac
}
trap cmc_security_cleanup EXIT

cmc_security_secret_value_pattern='(AKIA[0-9A-Z]{16}|github_pat_[0-9A-Za-z_]{20,}|gh[pousr]_[0-9A-Za-z]{30,}|sk-(proj|live|prod)-[0-9A-Za-z_-]{20,}|sk_(live|prod)_[0-9A-Za-z]{20,}|sb_secret_[0-9A-Za-z]{24,}|AIza[0-9A-Za-z_-]{30,}|GOCSPX-[0-9A-Za-z_-]{20,})'
cmc_security_source_secret_pattern="(${cmc_security_secret_value_pattern}|-----BEGIN (RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----)"
cmc_security_jwt_pattern='eyJ[0-9A-Za-z_-]{8,}\.[0-9A-Za-z_-]{8,}\.[0-9A-Za-z_-]{8,}'

cmc_security_contains_non_publishable_jwt() {
  local cmc_security_file="$1"
  local cmc_security_token
  local cmc_security_tokens
  local cmc_security_payload
  local cmc_security_padding
  local cmc_security_grep_status
  local cmc_security_role_status

  if cmc_security_tokens="$(
    LC_ALL=C grep -aEo -- "${cmc_security_jwt_pattern}" \
      "${cmc_security_file}"
  )"; then
    :
  else
    cmc_security_grep_status="$?"
    if [[ "${cmc_security_grep_status}" -eq 1 ]]; then
      return 1
    fi
    return 2
  fi

  while IFS= read -r cmc_security_token; do
    cmc_security_payload="${cmc_security_token#*.}"
    cmc_security_payload="${cmc_security_payload%%.*}"
    case "$((${#cmc_security_payload} % 4))" in
      0) cmc_security_padding='' ;;
      2) cmc_security_padding='==' ;;
      3) cmc_security_padding='=' ;;
      *) return 2 ;;
    esac
    if printf '%s' "${cmc_security_payload}${cmc_security_padding}" \
      | tr '_-' '/+' \
      | openssl base64 -d -A 2>/dev/null \
      | perl -MJSON::PP -e '
      use strict;
      use warnings;
      local $/;
      my $raw = <STDIN>;
      my $payload = eval { JSON::PP->new->utf8->decode($raw) };
      exit 2 if $@ || ref($payload) ne "HASH";
      exit 1 if $raw =~ /\\u[0-9A-Fa-f]{4}/;
      my $role_count = () = $raw =~ /"role"\s*:/g;
      exit 1 if $role_count != 1;
      exit 1 if !exists $payload->{role};
      exit 1 if ref($payload->{role});
      exit($payload->{role} eq "anon" ? 0 : 1);
    '; then
      continue
    else
      cmc_security_role_status="$?"
    fi
    if [[ "${cmc_security_role_status}" -eq 1 ]]; then
      return 0
    fi
    return 2
  done <<<"${cmc_security_tokens}"
  return 1
}

cmc_security_contains_private_key_pem() {
  local cmc_security_file="$1"
  local cmc_security_perl_status

  if ! command -v perl >/dev/null 2>&1; then
    return 2
  fi
  if perl -0777 -e '
    use strict;
    use warnings;
    my $path = shift;
    open my $handle, "<", $path or exit 2;
    binmode $handle;
    local $/;
    my $content = <$handle>;
    close $handle or exit 2;
    my $label = qr/(?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY/;
    while (
      $content =~
        /-----BEGIN ($label)-----[ \t\f\x0b\r]*\n(.*?)-----END \1-----/sg
    ) {
      my $body = $2;
      my $payload = "";
      my $payload_started = 0;
      my $valid = 1;
      for my $line (split /\n/, $body) {
        $line =~ s/\A[ \t\f\x0b\r]+//;
        $line =~ s/[ \t\f\x0b\r]+\z//;
        next if !$payload_started && $line eq "";
        next if !$payload_started && $line =~ /\A[A-Za-z0-9-]+:[^\r\n]*\z/;
        $payload_started = 1;
        $line =~ s/[ \t\f\x0b\r]//g;
        if ($line !~ /\A[A-Za-z0-9+\/=]+\z/) {
          $valid = 0;
          last;
        }
        $payload .= $line;
      }
      next if !$valid || length($payload) < 16 || length($payload) % 4 != 0;
      next if $payload !~ /\A[A-Za-z0-9+\/]+={0,2}\z/;
      exit 0;
    }
    exit 1;
  ' "${cmc_security_file}" 2>/dev/null; then
    return 0
  else
    cmc_security_perl_status="$?"
  fi
  if [[ "${cmc_security_perl_status}" -eq 1 ]]; then
    return 1
  fi
  return 2
}

cmc_security_file_has_prohibited_value() {
  local cmc_security_file="$1"
  local cmc_security_pattern="$2"
  local cmc_security_check_pem="${3:-false}"
  local cmc_security_scan_status

  if [[ ! -f "${cmc_security_file}" || ! -r "${cmc_security_file}" ]]; then
    return 2
  fi
  if LC_ALL=C grep -aEq -- "${cmc_security_pattern}" \
    "${cmc_security_file}"; then
    return 0
  else
    cmc_security_scan_status="$?"
  fi
  if [[ "${cmc_security_scan_status}" -ne 1 ]]; then
    return 2
  fi
  if cmc_security_contains_non_publishable_jwt "${cmc_security_file}"; then
    return 0
  else
    cmc_security_scan_status="$?"
  fi
  if [[ "${cmc_security_scan_status}" -ne 1 ]]; then
    return 2
  fi
  if [[ "${cmc_security_check_pem}" == 'true' ]]; then
    if cmc_security_contains_private_key_pem "${cmc_security_file}"; then
      return 0
    else
      cmc_security_scan_status="$?"
    fi
    if [[ "${cmc_security_scan_status}" -ne 1 ]]; then
      return 2
    fi
  fi
  return 1
}

cmc_security_file_has_prohibited_artifact_value() {
  local cmc_security_file="$1"
  local cmc_security_scan_status

  if [[ ! -f "${cmc_security_file}" || ! -r "${cmc_security_file}" ]]; then
    return 2
  fi

  # Google Maps iOS incorpora nel proprio binario un identificatore client pubblico
  # con forma AIza. Non è la chiave configurata dall'app: è delimitato da due
  # costanti interne stabili dell'SDK. L'eccezione resta quindi vincolata al contesto
  # binario esatto; qualunque altro token, anche nello stesso file, fallisce chiuso.
  if perl -0777 -e '
    use strict;
    use warnings;
    use Digest::SHA qw(sha256_hex);
    my $path = shift;
    open my $handle, "<", $path or exit 2;
    binmode $handle;
    local $/;
    my $content = <$handle>;
    close $handle or exit 2;
    my $secret = qr/(?:
      AKIA[0-9A-Z]{16}
      |github_pat_[0-9A-Za-z_]{20,}
      |gh[pousr]_[0-9A-Za-z]{30,}
      |sk-(?:proj|live|prod)-[0-9A-Za-z_-]{20,}
      |sk_(?:live|prod)_[0-9A-Za-z]{20,}
      |sb_secret_[0-9A-Za-z]{24,}
      |AIza[0-9A-Za-z_-]{30,}
      |GOCSPX-[0-9A-Za-z_-]{20,}
    )/x;
    my $maps_prefix = "X-Ios-Bundle-Identifier\0DeductQuota\0";
    my $maps_suffix =
      "\0unknown_ios\0mapsmobilesdks-pa.googleapis.com\0places.googleapis.com";
    my %maps_identifier_sha256 = map { $_ => 1 } (
      # Google Maps iOS 10.8.0; solo fingerprint, mai il valore.
      "13a99f83ec8ee2c628dfdfbfc8d9d0c9600c7fa6cdf4b1f8d558ea7f85006da3",
      # Sentinel sintetico usato esclusivamente dalla fixture positiva.
      "b62246d9aec15541f0d79cbfbfac795626ae348908d2c86f1ab31b5ee4a707b2",
      # Outer token sintetico: la fixture deve comunque rilevare il secret annidato.
      "b40f43848d3536c7f9b72557312b1134ba6aec3872b6e17b3ae895d7b39bce82",
    );
    while ($content =~ /(?=($secret))/g) {
      my $value = $1;
      my $start = $-[1];
      my $end = $+[1];
      my $prefix_start = $start - length($maps_prefix);
      my $is_maps_sdk_identifier =
        $value =~ /\AAIza[0-9A-Za-z_-]{35}\z/
        && $maps_identifier_sha256{sha256_hex($value)}
        && $prefix_start >= 0
        && substr($content, $prefix_start, length($maps_prefix)) eq $maps_prefix
        && substr($content, $end, length($maps_suffix)) eq $maps_suffix;
      next if $is_maps_sdk_identifier;
      exit 0;
    }
    exit 1;
  ' "${cmc_security_file}" 2>/dev/null; then
    return 0
  else
    cmc_security_scan_status="$?"
  fi
  if [[ "${cmc_security_scan_status}" -ne 1 ]]; then
    return 2
  fi
  if cmc_security_contains_non_publishable_jwt "${cmc_security_file}"; then
    return 0
  else
    cmc_security_scan_status="$?"
  fi
  if [[ "${cmc_security_scan_status}" -ne 1 ]]; then
    return 2
  fi
  if cmc_security_contains_private_key_pem "${cmc_security_file}"; then
    return 0
  else
    cmc_security_scan_status="$?"
  fi
  if [[ "${cmc_security_scan_status}" -ne 1 ]]; then
    return 2
  fi
  return 1
}

cmc_security_path_match_begin() {
  if shopt -q nocasematch; then
    cmc_security_restore_nocasematch=false
  else
    shopt -s nocasematch
    cmc_security_restore_nocasematch=true
  fi
}

cmc_security_path_match_end() {
  if [[ "${cmc_security_restore_nocasematch}" == 'true' ]]; then
    shopt -u nocasematch
  fi
}

cmc_security_source_path_is_forbidden() {
  local cmc_security_path="$1"
  local cmc_security_result=1
  local cmc_security_restore_nocasematch
  cmc_security_path_match_begin
  case "${cmc_security_path}" in
    config/*.local.json | */config/*.local.json | \
      .env | .env.* | */.env | */.env.* | \
      build/* | */build/* | \
      coverage/* | */coverage/* | \
      *.jks | *.keystore | *.key | *.pem | \
      *.p8 | *.p12 | *.pfx | *.cer | *.crt | *.der | \
      *.mobileprovision | \
      key.properties | */key.properties | \
      google-services.json | */google-services.json | \
      GoogleService-Info.plist | */GoogleService-Info.plist)
      case "${cmc_security_path}" in
        .env.example | .env.*.example | \
          */.env.example | */.env.*.example)
          ;;
        *)
          cmc_security_result=0
          ;;
      esac
      ;;
  esac
  cmc_security_path_match_end
  return "${cmc_security_result}"
}

cmc_security_artifact_path_is_forbidden() {
  local cmc_security_path="$1"
  local cmc_security_result=1
  local cmc_security_restore_nocasematch
  cmc_security_path_match_begin
  case "${cmc_security_path}" in
    config/*.local.json | */config/*.local.json | \
      .env | .env.* | */.env | */.env.* | \
      *.jks | *.keystore | *.key | *.pem | \
      *.p8 | *.p12 | *.pfx | *.cer | *.crt | *.der | \
      *.mobileprovision | \
      key.properties | */key.properties | \
      google-services.json | */google-services.json | \
      GoogleService-Info.plist | */GoogleService-Info.plist)
      cmc_security_result=0
      ;;
  esac
  cmc_security_path_match_end
  return "${cmc_security_result}"
}

cmc_security_scan_source_snapshot() {
  local cmc_security_snapshot_file="$1"
  local cmc_security_snapshot_path="$2"
  local cmc_security_snapshot_kind="$3"
  local cmc_security_scan_status

  if cmc_security_file_has_prohibited_value \
    "${cmc_security_snapshot_file}" \
    "${cmc_security_source_secret_pattern}"; then
    printf '%q: valore secret-shaped rilevato nello snapshot %s; contenuto non stampato.\n' \
      "${cmc_security_snapshot_path}" "${cmc_security_snapshot_kind}" >&2
    cmc_security_violation_count=$((cmc_security_violation_count + 1))
    return 0
  else
    cmc_security_scan_status="$?"
  fi
  if [[ "${cmc_security_scan_status}" -ne 1 ]]; then
    printf '%q: snapshot %s non verificabile; scan fail-closed.\n' \
      "${cmc_security_snapshot_path}" "${cmc_security_snapshot_kind}" >&2
    return 2
  fi
  return 0
}

cmc_security_index_list="${cmc_security_tmp_root}/git-index.records"
if ! git -C "${cmc_security_repo_root}" ls-files --stage -z \
  >"${cmc_security_index_list}"; then
  printf 'Security scan Git: enumerazione indice non verificabile.\n' >&2
  exit 1
fi

while IFS= read -r -d '' cmc_security_index_record; do
  cmc_security_index_metadata="${cmc_security_index_record%%$'\t'*}"
  cmc_security_path="${cmc_security_index_record#*$'\t'}"
  read -r cmc_security_mode cmc_security_object cmc_security_stage \
    <<<"${cmc_security_index_metadata}"
  cmc_security_tracked_count=$((cmc_security_tracked_count + 1))

  if [[ "${cmc_security_stage}" != '0' ]]; then
    printf '%q: indice Git con stage non risolto; scan fail-closed.\n' \
      "${cmc_security_path}" >&2
    exit 1
  fi

  if cmc_security_source_path_is_forbidden "${cmc_security_path}"; then
    printf '%q: path locale, credenziale o artifact non ammesso in Git.\n' \
      "${cmc_security_path}" >&2
    cmc_security_violation_count=$((cmc_security_violation_count + 1))
  fi

  if [[ "${cmc_security_mode}" != '100644' && \
    "${cmc_security_mode}" != '100755' ]]; then
    if [[ "${cmc_security_mode}" != '120000' ]]; then
      printf '%q: mode Git non supportato dal security scan.\n' \
        "${cmc_security_path}" >&2
      exit 1
    fi
  fi

  cmc_security_index_scan_file="$(
    mktemp "${cmc_security_tmp_root}/git-index-blob.XXXXXX"
  )"
  if ! git -C "${cmc_security_repo_root}" cat-file blob \
    "${cmc_security_object}" >"${cmc_security_index_scan_file}"; then
    printf 'Security scan Git: blob indice non leggibile.\n' >&2
    exit 1
  fi
  if ! cmc_security_scan_source_snapshot \
    "${cmc_security_index_scan_file}" \
    "${cmc_security_path}" \
    'index'; then
    exit 1
  fi

  cmc_security_worktree_path="${cmc_security_repo_root}/${cmc_security_path}"
  if [[ -L "${cmc_security_worktree_path}" ]]; then
    cmc_security_worktree_scan_file="$(
      mktemp "${cmc_security_tmp_root}/git-worktree-link.XXXXXX"
    )"
    if ! readlink "${cmc_security_worktree_path}" \
      >"${cmc_security_worktree_scan_file}"; then
      printf '%q: symlink worktree non leggibile; scan fail-closed.\n' \
        "${cmc_security_path}" >&2
      exit 1
    fi
  elif [[ -f "${cmc_security_worktree_path}" && \
    -r "${cmc_security_worktree_path}" ]]; then
    cmc_security_worktree_scan_file="${cmc_security_worktree_path}"
  else
    printf '%q: snapshot worktree non leggibile; scan fail-closed.\n' \
      "${cmc_security_path}" >&2
    exit 1
  fi
  if ! cmc_security_scan_source_snapshot \
    "${cmc_security_worktree_scan_file}" \
    "${cmc_security_path}" \
    'worktree'; then
    exit 1
  fi
done <"${cmc_security_index_list}"

if [[ "${cmc_security_tracked_count}" -eq 0 ]]; then
  printf 'Security scan non eseguibile: nessun file tracciato.\n' >&2
  exit 1
fi

if [[ "${#cmc_security_artifacts[@]}" -gt 0 ]]; then
  cmc_security_artifact_index=0
  for cmc_security_artifact in "${cmc_security_artifacts[@]}"; do
    if [[ ! -e "${cmc_security_artifact}" ]]; then
      printf 'Security scan artifact: target assente.\n' >&2
      exit 1
    fi
    cmc_security_artifact_index=$((cmc_security_artifact_index + 1))
    cmc_security_scan_root="${cmc_security_artifact}"
    cmc_security_archive_payload=''
    cmc_security_archive_metadata=''
    cmc_security_artifact_is_archive=false
    if [[ -f "${cmc_security_artifact}" ]]; then
      if perl -e '
        use strict;
        use warnings;
        my $path = shift;
        open my $handle, "<", $path or exit 2;
        binmode $handle;
        my $read = read $handle, my $magic, 2;
        close $handle or exit 2;
        exit 2 if !defined $read;
        exit($read == 2 && $magic eq "PK" ? 0 : 1);
      ' "${cmc_security_artifact}"; then
        cmc_security_artifact_is_archive=true
      else
        cmc_security_archive_probe_status="$?"
        if [[ "${cmc_security_archive_probe_status}" -ne 1 ]]; then
          printf 'Security scan artifact: tipo non verificabile.\n' >&2
          exit 1
        fi
      fi
    fi
    if [[ "${cmc_security_artifact_is_archive}" == true ]]; then
      cmc_security_scan_root="${cmc_security_tmp_root}/artifact-${cmc_security_artifact_index}"
      cmc_security_archive_payload="${cmc_security_tmp_root}/artifact-${cmc_security_artifact_index}.payload"
      cmc_security_archive_metadata="${cmc_security_tmp_root}/artifact-${cmc_security_artifact_index}.metadata"
      mkdir -p "${cmc_security_scan_root}"
      if ! unzip -tqq "${cmc_security_artifact}" || \
        ! unzip -oq "${cmc_security_artifact}" \
          -d "${cmc_security_scan_root}"; then
        printf 'Security scan artifact: archivio non leggibile.\n' >&2
        exit 1
      fi
      # Lo stream aggregato conserva anche entry ZIP duplicate che
      # l'estrazione sovrascrive, evitando che un valore vietato venga
      # nascosto dietro una seconda entry omonima.
      if ! unzip -p "${cmc_security_artifact}" \
        >"${cmc_security_archive_payload}"; then
        printf 'Security scan artifact: payload archivio non leggibile.\n' >&2
        exit 1
      fi
      # Nomi entry e commento sono distribuiti insieme al payload, quindi
      # partecipano allo stesso controllo secret-shaped senza essere stampati.
      if ! {
        unzip -Z1 "${cmc_security_artifact}"
        unzip -z "${cmc_security_artifact}"
      } >"${cmc_security_archive_metadata}"; then
        printf 'Security scan artifact: metadata archivio non leggibili.\n' >&2
        exit 1
      fi
      cmc_security_archive_metadata_bytes="$(
        wc -c <"${cmc_security_archive_metadata}" | tr -d '[:space:]'
      )"
      if [[ ! "${cmc_security_archive_metadata_bytes}" =~ ^[0-9]+$ || \
        "${cmc_security_archive_metadata_bytes}" -gt 4194304 ]]; then
        printf 'Security scan artifact: metadata archivio fuori limite.\n' >&2
        exit 1
      fi
    else
      case "${cmc_security_artifact}" in
        *.[aA][aA][bB] | *.[aA][pP][kK] | *.[zZ][iI][pP])
          printf 'Security scan artifact: archivio non leggibile.\n' >&2
          exit 1
          ;;
      esac
    fi

    if [[ -f "${cmc_security_scan_root}" ]]; then
      cmc_security_artifact_files=("${cmc_security_scan_root}")
    else
      cmc_security_artifact_files=()
      cmc_security_artifact_list="${cmc_security_tmp_root}/artifact-${cmc_security_artifact_index}.files"
      if ! find "${cmc_security_scan_root}" \
        \( -type f -o -type l \) -print0 \
        >"${cmc_security_artifact_list}"; then
        printf 'Security scan artifact: enumerazione non verificabile.\n' >&2
        exit 1
      fi
      while IFS= read -r -d '' cmc_security_artifact_file; do
        cmc_security_artifact_files+=("${cmc_security_artifact_file}")
      done <"${cmc_security_artifact_list}"
      if [[ -n "${cmc_security_archive_payload}" ]]; then
        cmc_security_artifact_files+=("${cmc_security_archive_payload}")
      fi
      if [[ -n "${cmc_security_archive_metadata}" ]]; then
        cmc_security_artifact_files+=("${cmc_security_archive_metadata}")
      fi
    fi

    for cmc_security_artifact_file in \
      "${cmc_security_artifact_files[@]}"; do
      cmc_security_artifact_file_count=$((cmc_security_artifact_file_count + 1))
      if [[ -L "${cmc_security_artifact_file}" ]]; then
        printf 'Security scan artifact: symlink non verificabile.\n' >&2
        exit 1
      fi
      if [[ -n "${cmc_security_archive_payload}" && \
        "${cmc_security_artifact_file}" == "${cmc_security_archive_payload}" ]]; then
        cmc_security_artifact_relative='__archive_payload__'
      elif [[ -n "${cmc_security_archive_metadata}" && \
        "${cmc_security_artifact_file}" == "${cmc_security_archive_metadata}" ]]; then
        cmc_security_artifact_relative='__archive_metadata__'
      elif [[ -f "${cmc_security_scan_root}" ]]; then
        cmc_security_artifact_relative="${cmc_security_scan_root##*/}"
      else
        cmc_security_artifact_relative="${cmc_security_artifact_file#"${cmc_security_scan_root}/"}"
      fi
      if cmc_security_artifact_path_is_forbidden \
        "${cmc_security_artifact_relative}"; then
        printf 'Artifact client: path credenziale/config vietato; contenuto non stampato.\n' \
          >&2
        cmc_security_violation_count=$((cmc_security_violation_count + 1))
      fi
      if cmc_security_file_has_prohibited_artifact_value \
        "${cmc_security_artifact_file}"; then
        printf 'Artifact client: valore secret-shaped rilevato; contenuto non stampato.\n' \
          >&2
        cmc_security_violation_count=$((cmc_security_violation_count + 1))
      else
        cmc_security_scan_status="$?"
        if [[ "${cmc_security_scan_status}" -ne 1 ]]; then
          printf 'Security scan artifact: file non leggibile; scan fail-closed.\n' \
            >&2
          exit 1
        fi
      fi
    done
  done

  if [[ "${cmc_security_artifact_file_count}" -eq 0 ]]; then
    printf 'Security scan artifact: nessun file verificabile.\n' >&2
    exit 1
  fi
fi

if [[ "${cmc_security_violation_count}" -ne 0 ]]; then
  printf 'Security scan client fallito: %d violazione/i; nessun valore esposto.\n' \
    "${cmc_security_violation_count}" >&2
  exit 1
fi

printf 'Security scan client: %d file tracciati, zero secret/config/artifact vietati.\n' \
  "${cmc_security_tracked_count}"
if [[ "${cmc_security_artifact_file_count}" -gt 0 ]]; then
  printf 'Security scan artifact: %d file, nessun secret privilegiato rilevato.\n' \
    "${cmc_security_artifact_file_count}"
fi

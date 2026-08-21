#!/usr/bin/env bash
set -euo pipefail

cmc_security_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_security_default_root="$(git -C "${cmc_security_script_dir}" rev-parse --show-toplevel)"
cmc_security_repo_root="${CMC_SECURITY_REPO_ROOT:-${cmc_security_default_root}}"
cmc_security_violation_count=0
cmc_security_tracked_count=0
cmc_security_artifact_file_count=0
cmc_security_artifact_total_bytes=0
cmc_security_artifacts=()
cmc_security_allow_ios_embedded_profile=false

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
    --allow-ios-embedded-profile)
      cmc_security_allow_ios_embedded_profile=true
      ;;
    *)
      printf 'Security scan: argomento non supportato.\n' >&2
      exit 1
      ;;
  esac
  shift
done

if [[ "${cmc_security_allow_ios_embedded_profile}" == true && \
  "${#cmc_security_artifacts[@]}" -ne 1 ]]; then
  printf 'Security scan: profilo iOS consentito solo per un artifact.\n' >&2
  exit 1
fi

if ! git -C "${cmc_security_repo_root}" rev-parse --is-inside-work-tree \
  >/dev/null 2>&1; then
  printf 'Security scan non eseguibile: repository Git non valido.\n' >&2
  exit 1
fi
if ! command -v perl >/dev/null 2>&1 || \
  ! command -v tr >/dev/null 2>&1 || \
  ! perl -MJSON::PP -MDigest::SHA -MMIME::Base64 -e 1 \
    >/dev/null 2>&1; then
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
cmc_security_contains_non_publishable_jwt() {
  local cmc_security_file="$1"
  local cmc_security_perl_status

  if perl -MJSON::PP -MMIME::Base64=decode_base64 -e '
    use strict;
    use warnings;
    my $path = shift;
    open my $handle, "<", $path or exit 2;
    binmode $handle;
    my $jwt = qr/eyJ[0-9A-Za-z_-]{8,16384}\.[0-9A-Za-z_-]{8,16384}\.[0-9A-Za-z_-]{8,16384}/;
    my $contains_non_publishable = sub {
      my ($content) = @_;
      while ($content =~ /($jwt)/g) {
        my @segments = split /\./, $1, -1;
        return 1 if @segments != 3;
        my $payload = $segments[1];
        return 1 if length($payload) % 4 == 1;
        $payload =~ tr/_-/+\//;
        $payload .= "=" x ((4 - length($payload) % 4) % 4);
        my $raw = decode_base64($payload);
        return 1 if !defined $raw || $raw =~ /\\u[0-9A-Fa-f]{4}/;
        my $decoded = eval { JSON::PP->new->utf8->decode($raw) };
        return 1 if $@ || ref($decoded) ne "HASH";
        my $role_count = () = $raw =~ /"role"\s*:/g;
        return 1 if $role_count != 1 || !exists $decoded->{role}
          || ref($decoded->{role}) || $decoded->{role} ne "anon";
      }
      return 0;
    };
    my $chunk_size = 1048576;
    my $overlap = 65536;
    my $carry = "";
    while (1) {
      my $read = read($handle, my $chunk, $chunk_size);
      exit 2 if !defined $read;
      last if $read == 0;
      my $content = $carry . $chunk;
      exit 0 if $contains_non_publishable->($content);
      # Un token che supera la finestra è non canonico e viene respinto senza
      # materializzarlo per intero.
      exit 0 if $content =~ /eyJ[0-9A-Za-z_-]{16385}/;
      exit 0 if $content =~ /
        eyJ[0-9A-Za-z_-]{8,16384}\.[0-9A-Za-z_-]{16385}
      /x;
      exit 0 if $content =~ /
        eyJ[0-9A-Za-z_-]{8,16384}\.
        [0-9A-Za-z_-]{8,16384}\.[0-9A-Za-z_-]{16385}
      /x;
      $carry = length($content) > $overlap
        ? substr($content, -$overlap)
        : $content;
    }
    close $handle or exit 2;
    exit($contains_non_publishable->($carry) ? 0 : 1);
  ' "${cmc_security_file}" 2>/dev/null; then
    return 0
  else
    cmc_security_perl_status="$?"
  fi
  [[ "${cmc_security_perl_status}" -eq 1 ]] && return 1
  return 2
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
  if perl -MJSON::PP -MMIME::Base64=decode_base64 -e '
    use strict;
    use warnings;
    use Digest::SHA qw(sha256_hex);
    my $path = shift;
    open my $handle, "<", $path or exit 2;
    binmode $handle;
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
    my $jwt = qr/eyJ[0-9A-Za-z_-]{8,}\.[0-9A-Za-z_-]{8,}\.[0-9A-Za-z_-]{8,}/;
    my $contains_non_publishable_jwt = sub {
      my ($content) = @_;
      while ($content =~ /($jwt)/g) {
        my $token = $1;
        my @segments = split /\./, $token, -1;
        return 1 if @segments != 3;
        my $payload = $segments[1];
        $payload =~ tr/_-/+\//;
        return 1 if length($payload) % 4 == 1;
        $payload .= "=" x ((4 - length($payload) % 4) % 4);
        my $raw = eval { decode_base64($payload) };
        return 1 if $@ || !defined $raw || $raw =~ /\\u[0-9A-Fa-f]{4}/;
        my $decoded = eval { JSON::PP->new->utf8->decode($raw) };
        return 1 if $@ || ref($decoded) ne "HASH";
        my $role_count = () = $raw =~ /"role"\s*:/g;
        return 1 if $role_count != 1 || !exists $decoded->{role}
          || ref($decoded->{role}) || $decoded->{role} ne "anon";
      }
      return 0;
    };
    my $contains_private_key = sub {
      my ($content) = @_;
      my $label = qr/(?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY/;
      while (
        $content =~
          /-----BEGIN ($label)-----[ \t\f\x0b\r]*\n(.*?)-----END \1-----/sg
      ) {
        my $body = $2;
        my $payload = "";
        my $started = 0;
        my $valid = 1;
        for my $line (split /\n/, $body) {
          $line =~ s/\A[ \t\f\x0b\r]+//;
          $line =~ s/[ \t\f\x0b\r]+\z//;
          next if !$started && $line eq "";
          next if !$started && $line =~ /\A[A-Za-z0-9-]+:[^\r\n]*\z/;
          $started = 1;
          $line =~ s/[ \t\f\x0b\r]//g;
          if ($line !~ /\A[A-Za-z0-9+\/=]+\z/) {
            $valid = 0;
            last;
          }
          $payload .= $line;
        }
        return 1 if $valid && length($payload) >= 16
          && length($payload) % 4 == 0
          && $payload =~ /\A[A-Za-z0-9+\/]+={0,2}\z/;
      }
      return 0;
    };
    my $maps_prefix = "X-Ios-Bundle-Identifier\0DeductQuota\0";
    # Il linker può collocare dopo endpoint Maps una costante Places oppure
    # un simbolo `google.internal.*`. Il confine stabile termina al NUL di Maps;
    # fingerprint e prefisso restano entrambi obbligatori.
    my $maps_suffix =
      "\0unknown_ios\0mapsmobilesdks-pa.googleapis.com\0";
    my %maps_identifier_sha256 = map { $_ => 1 } (
      # Identificatore pubblico del Google Maps iOS SDK locked; solo fingerprint.
      "13a99f83ec8ee2c628dfdfbfc8d9d0c9600c7fa6cdf4b1f8d558ea7f85006da3",
      # Sentinel sintetico usato esclusivamente dalla fixture positiva.
      "b62246d9aec15541f0d79cbfbfac795626ae348908d2c86f1ab31b5ee4a707b2",
      # Outer token sintetico: la fixture deve comunque rilevare il secret annidato.
      "b40f43848d3536c7f9b72557312b1134ba6aec3872b6e17b3ae895d7b39bce82",
    );
    my $scan = sub {
      my ($content) = @_;
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
        return 1;
      }
      return 1 if $contains_non_publishable_jwt->($content);
      return 1 if $contains_private_key->($content);
      # Costanti e plist possono codificare credenziali ASCII in UTF-16LE/BE.
      for my $encoded_pattern (
        qr/((?:[\x09\x0a\x0d\x20-\x7e]\x00){8,})/,
        qr/((?:\x00[\x09\x0a\x0d\x20-\x7e]){8,})/
      ) {
        while ($content =~ /$encoded_pattern/g) {
          my $decoded = $1;
          $decoded =~ s/\x00//g;
          return 1 if $decoded =~ /$secret/
            || $contains_non_publishable_jwt->($decoded)
            || $contains_private_key->($decoded);
        }
      }
      return 0;
    };
    my $carry = "";
    my $chunk_size = 4 * 1024 * 1024;
    my $overlap = 1024 * 1024;
    while (1) {
      my $read = read $handle, my $chunk, $chunk_size;
      exit 2 if !defined $read;
      last if $read == 0;
      my $content = $carry . $chunk;
      exit 0 if $scan->($content);
      if (length($content) > $overlap) {
        $carry = substr($content, -$overlap);
      } else {
        $carry = $content;
      }
    }
    close $handle or exit 2;
    exit 0 if $scan->($carry);
    exit 1;
  ' "${cmc_security_file}" 2>/dev/null; then
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
  if [[ "${cmc_security_allow_ios_embedded_profile}" == true && \
    "${cmc_security_path}" == 'embedded.mobileprovision' ]]; then
    cmc_security_path_match_end
    return 1
  fi
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
  for cmc_security_archive_command in awk head unzip wc; do
    if ! command -v "${cmc_security_archive_command}" >/dev/null 2>&1; then
      printf 'Security scan artifact: tooling archive assente.\n' >&2
      exit 1
    fi
  done
  cmc_security_artifact_index=0
  for cmc_security_artifact in "${cmc_security_artifacts[@]}"; do
    if [[ ! -e "${cmc_security_artifact}" ]]; then
      printf 'Security scan artifact: target assente.\n' >&2
      exit 1
    fi
    if [[ "${cmc_security_allow_ios_embedded_profile}" == true ]]; then
      case "${cmc_security_artifact}" in
        *.app) ;;
        *)
          printf 'Security scan artifact: scope profilo iOS invalido.\n' >&2
          exit 1
          ;;
      esac
      [[ -d "${cmc_security_artifact}" && \
        -f "${cmc_security_artifact}/embedded.mobileprovision" && \
        ! -L "${cmc_security_artifact}/embedded.mobileprovision" ]] || {
        printf 'Security scan artifact: profilo iOS non verificabile.\n' >&2
        exit 1
      }
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
      if ! cmc_security_archive_summary="$(
        LC_ALL=C unzip -Z -t "${cmc_security_artifact}" 2>/dev/null
      )"; then
        printf 'Security scan artifact: sommario archivio non verificabile.\n' >&2
        exit 1
      fi
      cmc_security_archive_entry_count="$(
        awk '/ files?, / { value = $1 } END { print value }' \
          <<<"${cmc_security_archive_summary}"
      )"
      cmc_security_archive_uncompressed_bytes="$(
        awk '/ files?, / { value = $3 } END { print value }' \
          <<<"${cmc_security_archive_summary}"
      )"
      cmc_security_archive_compressed_bytes="$(
        awk '/ files?, / { value = $6 } END { print value }' \
          <<<"${cmc_security_archive_summary}"
      )"
      cmc_security_archive_container_bytes="$(
        wc -c <"${cmc_security_artifact}" | tr -d '[:space:]'
      )"
      if [[ ! "${cmc_security_archive_entry_count}" =~ ^[0-9]+$ || \
        ! "${cmc_security_archive_uncompressed_bytes}" =~ ^[0-9]+$ || \
        ! "${cmc_security_archive_compressed_bytes}" =~ ^[0-9]+$ || \
        ! "${cmc_security_archive_container_bytes}" =~ ^[0-9]+$ ]]; then
        printf 'Security scan artifact: sommario archivio invalido.\n' >&2
        exit 1
      fi
      if [[ "${cmc_security_archive_entry_count}" -gt 2048 || \
        "${cmc_security_archive_uncompressed_bytes}" -gt 536870912 || \
        "${cmc_security_archive_compressed_bytes}" -gt 536870912 || \
        "${cmc_security_archive_container_bytes}" -eq 0 || \
        "${cmc_security_archive_container_bytes}" -gt 536870912 || \
        "${cmc_security_archive_compressed_bytes}" -gt \
          "${cmc_security_archive_container_bytes}" ]] || \
        { [[ "${cmc_security_archive_compressed_bytes}" -eq 0 ]] && \
          [[ "${cmc_security_archive_uncompressed_bytes}" -ne 0 ]]; } || \
        { [[ "${cmc_security_archive_compressed_bytes}" -gt 0 ]] && \
          [[ "${cmc_security_archive_uncompressed_bytes}" -gt \
            $((cmc_security_archive_compressed_bytes * 200)) ]]; }; then
        printf 'Security scan artifact: limiti archive superati.\n' >&2
        exit 1
      fi
      cmc_security_scan_root="${cmc_security_tmp_root}/artifact-${cmc_security_artifact_index}"
      cmc_security_archive_payload="${cmc_security_tmp_root}/artifact-${cmc_security_artifact_index}.payload"
      cmc_security_archive_metadata="${cmc_security_tmp_root}/artifact-${cmc_security_artifact_index}.metadata"
      mkdir -p "${cmc_security_scan_root}"
      # I size del central directory sono input non fidati. Materializza prima
      # lo stream aggregato con un cap effettivo: `head` interrompe `unzip`
      # oltre 512 MiB e `pipefail` trasforma il SIGPIPE in rifiuto fail-closed.
      if ! LC_ALL=C unzip -p "${cmc_security_artifact}" | \
        head -c 536870913 >"${cmc_security_archive_payload}"; then
        printf 'Security scan artifact: payload archivio fuori limite.\n' >&2
        exit 1
      fi
      cmc_security_archive_actual_bytes="$(
        wc -c <"${cmc_security_archive_payload}" | tr -d '[:space:]'
      )"
      if [[ ! "${cmc_security_archive_actual_bytes}" =~ ^[0-9]+$ || \
        "${cmc_security_archive_actual_bytes}" -gt 536870912 || \
        "${cmc_security_archive_actual_bytes}" -ne \
          "${cmc_security_archive_uncompressed_bytes}" ]] || \
        [[ "${cmc_security_archive_actual_bytes}" -gt \
          $((cmc_security_archive_container_bytes * 200)) ]]; then
        printf 'Security scan artifact: payload archivio incoerente.\n' >&2
        exit 1
      fi
      if ! unzip -tqq "${cmc_security_artifact}" || \
        ! unzip -oq "${cmc_security_artifact}" \
          -d "${cmc_security_scan_root}"; then
        printf 'Security scan artifact: archivio non leggibile.\n' >&2
        exit 1
      fi
      # Lo stream aggregato già materializzato conserva anche entry ZIP
      # duplicate che l'estrazione sovrascrive, evitando che un valore vietato
      # venga nascosto dietro una seconda entry omonima.
      # Il central directory verbose comprende nomi, archive comment, commenti
      # per-entry ed extra field. `head` rende il bound preventivo: il pipefail
      # rifiuta lo stream se `unzip` viene interrotto oltre 4 MiB.
      if ! LC_ALL=C unzip -Z -v "${cmc_security_artifact}" | \
        head -c 4194305 >"${cmc_security_archive_metadata}"; then
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
      cmc_security_artifact_list="${cmc_security_tmp_root}/artifact-${cmc_security_artifact_index}.entries"
      if ! find "${cmc_security_scan_root}" -print0 | perl -e '
        use strict;
        use warnings;
        binmode STDIN;
        binmode STDOUT;
        local $/ = "\0";
        local $! = 0;
        my $count = 0;
        while (defined(my $entry = <STDIN>)) {
          exit 3 if ++$count > 4096;
          print $entry or exit 2;
        }
        exit 2 if $!;
        exit 0;
      ' >"${cmc_security_artifact_list}"; then
        printf 'Security scan artifact: enumerazione fuori limite o non verificabile.\n' >&2
        exit 1
      fi
      cmc_security_artifact_entry_count=0
      while IFS= read -r -d '' cmc_security_artifact_entry; do
        cmc_security_artifact_entry_count=$((
          cmc_security_artifact_entry_count + 1
        ))
        if [[ "${cmc_security_artifact_entry_count}" -gt 4096 ]]; then
          printf 'Security scan artifact: numero entry fuori limite.\n' >&2
          exit 1
        fi
        if [[ -f "${cmc_security_artifact_entry}" || \
          -L "${cmc_security_artifact_entry}" ]]; then
          if [[ $((cmc_security_artifact_file_count + \
            ${#cmc_security_artifact_files[@]})) -ge 4096 ]]; then
            printf 'Security scan artifact: numero file fuori limite.\n' >&2
            exit 1
          fi
          cmc_security_artifact_files+=("${cmc_security_artifact_entry}")
        fi
      done <"${cmc_security_artifact_list}"
      if [[ -n "${cmc_security_archive_payload}" ]]; then
        cmc_security_artifact_files+=("${cmc_security_archive_payload}")
      fi
      if [[ -n "${cmc_security_archive_metadata}" ]]; then
        cmc_security_artifact_files+=("${cmc_security_archive_metadata}")
      fi
      if [[ -n "${cmc_security_archive_payload}" ]]; then
        # Anche il container raw è bounded dal preflight e copre byte metadata
        # non normalizzati dal formatter Info-ZIP.
        cmc_security_artifact_files+=("${cmc_security_artifact}")
      fi
    fi

    for cmc_security_artifact_file in \
      "${cmc_security_artifact_files[@]}"; do
      cmc_security_artifact_file_count=$((cmc_security_artifact_file_count + 1))
      if [[ "${cmc_security_artifact_file_count}" -gt 4096 ]]; then
        printf 'Security scan artifact: numero file fuori limite.\n' >&2
        exit 1
      fi
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
      elif [[ -n "${cmc_security_archive_payload}" && \
        "${cmc_security_artifact_file}" == "${cmc_security_artifact}" ]]; then
        cmc_security_artifact_relative='__archive_container__'
      elif [[ -f "${cmc_security_scan_root}" ]]; then
        cmc_security_artifact_relative="${cmc_security_scan_root##*/}"
      else
        cmc_security_artifact_relative="${cmc_security_artifact_file#"${cmc_security_scan_root}/"}"
      fi
      cmc_security_artifact_file_bytes="$(
        wc -c <"${cmc_security_artifact_file}" | tr -d '[:space:]'
      )"
      if [[ ! "${cmc_security_artifact_file_bytes}" =~ ^[0-9]+$ ]]; then
        printf 'Security scan artifact: size file non verificabile.\n' >&2
        exit 1
      fi
      case "${cmc_security_artifact_relative}" in
        __archive_payload__ | __archive_container__ | __archive_metadata__) ;;
        *)
          if [[ "${cmc_security_artifact_file_bytes}" -gt 134217728 ]]; then
            printf 'Security scan artifact: file fuori limite.\n' >&2
            exit 1
          fi
          cmc_security_artifact_total_bytes=$((
            cmc_security_artifact_total_bytes + cmc_security_artifact_file_bytes
          ))
          if [[ "${cmc_security_artifact_total_bytes}" -gt 536870912 ]]; then
            printf 'Security scan artifact: payload aggregato fuori limite.\n' >&2
            exit 1
          fi
          ;;
      esac
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

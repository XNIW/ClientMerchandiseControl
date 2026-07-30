# TASK-002 — Integrità repository esterni

Confronto finale read-only: `2026-07-30T19:04:34Z`.

Metodologia ripetuta identica tra baseline e verifica finale, senza fetch o operazioni
mutative. Il Fix ha rieseguito la procedura il `2026-07-30T19:28:52Z`, exit `0`: tutti
gli otto digest coincidono con la tabella.

Algoritmo esatto usato su macOS/zsh, con il path del repository passato come unico
argomento:

```zsh
#!/bin/zsh
set -euo pipefail

export GIT_OPTIONAL_LOCKS=0
export LC_ALL=C

repo_dir=${1:?"usage: $0 /path/to/repository"}

status_sha256() {
  git -C "$repo_dir" \
    status --porcelain=v2 -z --branch --untracked-files=all |
    shasum -a 256 |
    awk '{print $1}'
}

content_fingerprint_v1() {
  {
    printf 'external-repo-fingerprint-v1\0'

    git -C "$repo_dir" \
      status --porcelain=v2 -z --branch --untracked-files=all

    printf '\0TRACKED_DIFF_HEAD\0'

    git -C "$repo_dir" \
      diff --binary --no-ext-diff --no-textconv HEAD --

    printf '\0UNTRACKED_BLOBS\0'

    while IFS= read -r -d '' rel; do
      printf 'PATH\0%s\0' "$rel"

      if [ -L "$repo_dir/$rel" ]; then
        printf 'SYMLINK\0%s\0' "$(readlink "$repo_dir/$rel")"
      elif [ -f "$repo_dir/$rel" ]; then
        printf 'FILE\0'
        shasum -a 256 < "$repo_dir/$rel"
      else
        printf 'SPECIAL\0'
        stat -f '%HT %p %z' "$repo_dir/$rel"
      fi
    done < <(
      git -C "$repo_dir" \
        ls-files --others --exclude-standard -z
    )
  } |
    shasum -a 256 |
    awk '{print $1}'
}

printf 'STATUS_SHA256 %s\n' "$(status_sha256)"
printf 'CONTENT_FINGERPRINT_V1 %s\n' "$(content_fingerprint_v1)"
```

| Repository | HEAD e branch | STATUS SHA-256 | CONTENT SHA-256 | Esito |
|---|---|---|---|---|
| `MerchandiseControlSplitView` | `c21de310c0a717f481a79d938888cbb99e8f930c`, `integrate/mac-final-android-20260717T150455Z` | `22b76cb8ac3be8dec3ae7d179d91ce7540eb236b5636f739fac508b689c6b124` | `663126bab110a1d34ae84785be3f5fa5d8ba575426e94c040d424de0fc0ccac6` | `PASS`, 1 record dirty invariato |
| `iOSMerchandiseControl` | `c1b7b706c5f05cd7e8dda74cea1122f6483df7ec`, `main` | `38a40f3a4f4431537fff8b08260b601979e964ba6a4163dacc9f2bd0bc2467fc` | `5523e8b90907ab030e0cda11a46957f0a75e6b56a7ad6c8351a2696fa7cfa32c` | `PASS`, 1 record dirty invariato |
| `merchandise-control-admin-web` | `710ff981f7bb0381159724ec02bbfec39a27eedf`, `main` | `76d58e31e7ebff589411e454be56796ddcdd504314e6797dcbb7fb0004626d0e` | `c991533cf159f0c068e02a6f09eeeed7fbfe6b62ab2d802b38b5839f29529db4` | `PASS`, clean invariato |
| `Win7POS` | `81acd479c187469fe0dc31f9b0fb3a162312c1cc`, `backup/win7pos-dirty-20260722-81acd479` | `a8ba743eb2358a9ca4ea09c5215517d116ba4d771fd36e4dd2fa6a4fdaf0b822` | `4aeda6ea6c50367bc0988667caea0258b9dcc76bee0e5f0a78a31d361733f5bc` | `PASS`, 13 record dirty invariati |

Risultato globale: `PASS` zero-write 4/4. Nessun repository esterno è stato modificato.

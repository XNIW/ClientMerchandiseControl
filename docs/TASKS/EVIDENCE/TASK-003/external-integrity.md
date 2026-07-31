# TASK-003 — Integrità delle fonti esterne

## Esito

`PASS` read-only per quattro repository Git, un workspace storico non-Git e i metadata
del progetto Supabase canonico. Nessun `fetch`, checkout, clean, reset, write, apply,
deploy o modifica remota è stato eseguito.

Le fingerprint Git finali del 2026-07-30T20:38:14Z coincidono byte-per-byte con la
baseline già chiusa da TASK-002 il 2026-07-30T19:28:52Z e con HEAD/dirty state rilevati
all'apertura dell'audit TASK-003. Il riuso della baseline precedente è esplicito: non
viene presentato come un nuovo commit o come prova dello stato remoto.

## Algoritmo Git riproducibile

Algoritmo eseguito su macOS/zsh. Il path assoluto è un input locale e non entra nella
evidence; il digest include branch/status, diff tracked rispetto a `HEAD` e contenuto
degli untracked non ignorati.

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

## Repository Git

| Repository | HEAD e branch | Dirty baseline sanitizzata | STATUS SHA-256 | CONTENT SHA-256 | Esito |
|---|---|---|---|---|---|
| `MerchandiseControlSplitView` | `c21de310c0a717f481a79d938888cbb99e8f930c`, `integrate/mac-final-android-20260717T150455Z` | 1 untracked evidence log | `22b76cb8ac3be8dec3ae7d179d91ce7540eb236b5636f739fac508b689c6b124` | `663126bab110a1d34ae84785be3f5fa5d8ba575426e94c040d424de0fc0ccac6` | `PASS`, invariato |
| `iOSMerchandiseControl` | `c1b7b706c5f05cd7e8dda74cea1122f6483df7ec`, `main` | 1 xcscheme tracked modificato | `38a40f3a4f4431537fff8b08260b601979e964ba6a4163dacc9f2bd0bc2467fc` | `5523e8b90907ab030e0cda11a46957f0a75e6b56a7ad6c8351a2696fa7cfa32c` | `PASS`, invariato |
| `merchandise-control-admin-web` | `710ff981f7bb0381159724ec02bbfec39a27eedf`, `main` | clean | `76d58e31e7ebff589411e454be56796ddcdd504314e6797dcbb7fb0004626d0e` | `c991533cf159f0c068e02a6f09eeeed7fbfe6b62ab2d802b38b5839f29529db4` | `PASS`, invariato |
| `Win7POS` | `81acd479c187469fe0dc31f9b0fb3a162312c1cc`, `backup/win7pos-dirty-20260722-81acd479` | 12 tracked modificati, 1 untracked | `a8ba743eb2358a9ca4ea09c5215517d116ba4d771fd36e4dd2fa6a4fdaf0b822` | `4aeda6ea6c50367bc0988667caea0258b9dcc76bee0e5f0a78a31d361733f5bc` | `PASS`, invariato |

Dirty records osservati:

- Android: `docs/TASKS/evidence/TASK-137/android-instrumentation.log`, untracked.
- iOS:
  `iOSMerchandiseControl.xcodeproj/xcshareddata/xcschemes/iOSMerchandiseControl.xcscheme`,
  tracked modificato.
- POS:
  `docs/AI_WORKLOG.md`, `scripts/check-pos-catalog-pull.ps1`,
  `CatalogSyncPolicy.cs`, `CatalogSyncTrigger.cs`,
  `PosOnlineTransportContracts.cs`, `CatalogShopStateRepository.cs`,
  `PosCatalogPullService.cs`, `PosOnlineSyncSupervisorHost.cs` e quattro test tracked
  modificati; `CatalogRemoteFailurePolicy.cs` untracked.

I nomi POS sono registrati soltanto per delimitare la baseline. L'audit architetturale
non assume canonico il contenuto dirty e non lo modifica.

## Workspace storico non-Git

Il workspace `MerchandiseControlSupabase` non possiede `.git`, quindi non è possibile
produrre HEAD, branch o una fingerprint Git equivalente. È stato usato un manifest
metadata relativo e sanitizzato; il digest non contiene né pubblica il path assoluto.

```zsh
#!/bin/zsh
set -euo pipefail

workspace_dir=${1:?"usage: $0 /path/to/workspace"}
export LC_ALL=C

(
  cd "$workspace_dir"
  printf 'non-git-metadata-manifest-v1\0'
  while IFS= read -r -d '' rel; do
    stat -f '%N\t%z\t%m' "$rel"
  done < <(find . -type f -print0 | sort -z)
) |
  shasum -a 256 |
  awk '{print $1}'
```

| Check | Valore iniziale | Valore finale | Esito |
|---|---|---|---|
| `NON_GIT_METADATA_MANIFEST_V1` | `738850697a93fa81cc0ba260bf599b9030faf57a32c9a36ff23ab31cff116247` | `738850697a93fa81cc0ba260bf599b9030faf57a32c9a36ff23ab31cff116247` | `PASS` |
| File totali | `425` | `425` | `PASS` |
| Migration SQL | `18` | `18` | `PASS` |
| File function diversi da README | `0` | `0` | `PASS` |

Questa fingerprint prova che path relativo, size e mtime non sono cambiati durante il
controllo. Non sostituisce Git, non prova contenuto/live parity e non promuove il
workspace a migration authority.

## Supabase remoto, metadata sanitizzati

Il progetto remoto non è un filesystem Git, quindi non riceve una content fingerprint.
La prova zero-write consiste nella allowlist delle sole operazioni read-only e nei
risultati sanitizzati:

| Check read-only | Risultato sanitizzato |
|---|---|
| Project list/status | unico `merchandisecontrol-dev`, ref `jpgo…kyvm`, `ACTIVE_HEALTHY`, `sa-east-1` |
| Branch list | solo `main` |
| Edge Functions list | `0` |
| Migration ledger | `96` migration logiche |
| `supabase migration list --linked` | 95 versioni 1:1 + remap TASK-142 locale `20260727055520` / remoto `20260727084040` |
| Metadata `shops` | `shop_id uuid NOT NULL` |
| Metadata grants | grant `anon` legacy osservato su `products` e `history_entries`; nessun uso autorizzato dal contratto |

Non sono stati eseguiti SQL mutativi, `db push`, migration repair, deploy, creazione o
modifica branch, modifica Auth, Storage write o invocazione mutativa.

## Confronto workspace storico / Admin linked

| Caratteristica | Workspace storico | Repository Admin linked |
|---|---|---|
| Provenance | non-Git | Git, HEAD fisso, `main` clean |
| Migration locali | 18 | 96 |
| Linked parity verificabile | no | sì, ledger e workflow guarded |
| Edge Functions implementate | 0, README-only | 0, directory assente |
| Autorità | evidence genealogica | migration/server contract authority corrente |
| Uso consentito | confronto storico read-only | source versionata per futuri task schema/API |

Diciassette basename migration storici ricorrono nell'Admin. Il solo basename storico
non trovato è `20260618141000_task135_harden_task108_backup_tables.sql`; l'osservazione
non autorizza copy/apply e richiede un futuro confronto semantico sotto TASK-005.

## Client worktree e confinamento

Baseline Client letta prima delle modifiche assegnate:

- HEAD `f3905caf3a4abf7b2682b5dcd9ed491dba019ea0`;
- branch `milestone/003-004-storefront-contract-environments`;
- erano già presenti modifiche concorrenti a documenti TASK-003 fuori dai tre file di
  questo incarico.

Questo incarico modifica esclusivamente:

- `docs/ARCHITECTURE/CROSS-REPO-OWNERSHIP.md`;
- `docs/TASKS/EVIDENCE/TASK-003/source-audit.md`;
- `docs/TASKS/EVIDENCE/TASK-003/external-integrity.md`.

Le modifiche concorrenti non sono state pulite, riscritte, staged o incluse come claim
di questo audit.

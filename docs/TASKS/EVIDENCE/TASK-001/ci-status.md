# GitHub Actions

- **Stato verificato**: `PASS`
- **Workflow**: `CI`
- **Pull Request**: `#1`
- **Run tecnico post-fix di riferimento**: `30555712533`
- **URL**: https://github.com/XNIW/ClientMerchandiseControl/actions/runs/30555712533
- **Commit verificato**: `3f0d992a7c1b6e9f9291e7617b53c0cf6c3f8734`
- **Workflow validato staticamente**: `PASS`
- **Quality**: `PASS`, 1m59
- **Android debug build**: `PASS`, 7m07
- **iOS Simulator debug build**: `PASS`, 3m06
- **Step**: tutti `PASS`
- **Annotazioni**: 0 per ciascun job.

## Verifica sullo SHA revisionato finale

- **Run**: `30557641291`
- **Commit**: `975ce7294555446b10eddb373769f8604b45c37c`
- **Evento**: `pull_request`
- **Conclusione**: `PASS`
- **Quality**: `PASS`, 1m54s
- **Android debug build**: `PASS`, 7m32s
- **iOS Simulator debug build**: `PASS`, 3m28s
- **Step**: tutti `PASS`
- **Annotazioni**: 0 per ciascun job

Il commit documentale di closeout avvia un nuovo run. Il relativo SHA e il dettaglio dei
job vengono verificati dopo il push e riportati nello stato della PR e nell'handoff,
evitando il ciclo infinito evidence -> commit -> CI -> evidence.

Il run storico `30514420504` aveva già confermato `actions/checkout@v7`, ma il tag era
ancora mutabile. Il run post-fix verifica i riferimenti action a SHA, il resolver Flutter,
il lockfile enforced, il diff delle localizzazioni e i tre job completi senza annotazioni.

Il commit documentale immutabile che contiene questa evidence avvia un ulteriore run sullo
SHA finale. Per evitare un ciclo infinito di commit evidence -> CI, il relativo run viene
verificato dopo il push e riportato nella descrizione della PR e nell'handoff finale.

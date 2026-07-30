# GitHub Actions

- **Stato verificato**: `PASS`
- **Workflow**: `CI`
- **Pull Request**: `#1`
- **Run di riferimento**: `30514420504`
- **URL**: https://github.com/XNIW/ClientMerchandiseControl/actions/runs/30514420504
- **Commit verificato**: `4a3d502ab9bfe090e147e7c3d64611c01f84ca31`
- **Workflow validato staticamente**: `PASS`
- **Quality**: `PASS`
- **Android debug build**: `PASS`
- **iOS Simulator debug build**: `PASS`
- **Annotazioni**: nessuna.

Il primo run `30514045128` era anch'esso `PASS`, ma segnalava la deprecazione Node.js 20
di `actions/checkout@v4`. Il workflow è stato aggiornato a `actions/checkout@v7`; il run
di riferimento sopra conferma la correzione senza nuove annotazioni.

Il commit immutabile di tracking che contiene questa evidence avvia un ulteriore run.
L'handoff è valido soltanto se anche i check correnti della PR sul commit finale sono
`PASS`; il relativo URL viene riportato nella descrizione della PR.

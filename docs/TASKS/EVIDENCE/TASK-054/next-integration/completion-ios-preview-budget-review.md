# Review distinta preview e budget iOS

**APPROVED_SOURCE_CODE_ONLY**, commit `7e7ecd2c9fe073665025cd88220648ca538bb7eb`, baseline `16e46817d9da5f4a5ce0fbca89137f2652f52b56`. Zero finding P0/P1/P2/P3 nei quattro file autorizzati; implementazione non modificata.

Verifiche autonome:16 regressioni preview,31 PNG e6 ownership PASS; pins, sintassi shell/Python, diff e security992 file exit0. Cinque ulteriori PoC distinti verificano processi/pipe propri reali, sips e receipt parziali/privacy. Trigger e sei altri budget invariati; raw upload byte-identico, antecedente alle preview.

Prova sips reale:141 PNG sintetici (137 visual+4 OS),7.417s,3,076,110 byte raw→1,321,408 byte preview. Tutti i raw e il file JSON sentinella byte-identici; manifest completo con associazioni relative/hash/dimensioni verificati. Frame ritratto/paesaggio conservano tutti i quattro angoli, senza crop; file piccolo copiato byte-identico. I pixel resampled cambiano: confronto RGB esatto iniziale respinto come aspettativa errata del PoC, raw RED preservato; delta osservato≤4/255.

Il budget35min lascia103s nominali oltre1097+900s, rispetto ai22s storici di cleanup/raw-upload/post e al budget preview45s (step60s). È una proposta finita supportata dalla misura, non prova di completamento o somma garantita di tutti i massimi di rete/cleanup. I timeout dei comandi nativi restano identici.

Nessuna cattura→NOT_RUN esplicito nel manifest; un errore di conversione, timeout o cleanup non diventa PASS. Preview esclusivamente diagnostiche: nessuna approvazione UX/app né prova nativa. Non eseguiti push, CI, build, device/simulator o download. Tutti i comandi propri terminali, worktree pulito e quattro hash congelati riverificati.

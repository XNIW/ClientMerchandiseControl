# Mobile architecture

## Stack

- Flutter e Dart stable;
- soli target Android/Kotlin e iOS/Swift;
- Material 3 con adattamenti idiomatici iOS;
- Riverpod per stato e dependency injection;
- go_router per navigazione dichiarativa;
- Supabase Flutter come client futuro;
- gen_l10n e intl.

## Struttura

L'architettura è feature-first, coerente con MVVM:

- View: widget e composizione UI;
- ViewModel/controller: stato e orchestrazione quando la feature lo richiede;
- repository: accesso a una fonte dati;
- service: integrazione tecnica;
- model/use case: soltanto quando aggiunge valore reale.

Non vengono creati livelli o interfacce vuoti. La shell, la configurazione, il design
system e i widget foundation hanno responsabilità concrete; repository e ViewModel
arrivano insieme alle feature data-backed.

## App e navigazione

`main.dart` delega a `bootstrap.dart`. Il bootstrap legge configurazione compile-time,
valida l'ambiente, inizializza Supabase solo con URL e publishable key completi e avvia
`ProviderScope`.

`ClientMerchandiseControlApp` compone tema, localizzazione e router.
`StatefulShellRoute.indexedStack` mantiene quattro branch — Home, Catalogo, Carrello e
Account — e ne preserva lo stato. Dalle tab root secondarie il back ritorna a Home.

In development senza configurazione l'app resta offline e usabile e mostra un banner
diagnostico debug accessibile. In production una configurazione incompleta è un errore
esplicito.

## Design system

`AppTheme` è l'unico composition root light/dark. Token primitivi, semantic colors e
widget foundation sono descritti in `DESIGN-SYSTEM.md`. Le feature non definiscono
palette, font scale, breakpoint o spacing paralleli.

## Dati e sicurezza

Il client consumerà soltanto il futuro dominio Storefront protetto server-side. Non
accede all'inventory operativa, non custodisce secret privilegiati e non autorizza
pubblicazione, prezzo, disponibilità, hold, fulfillment o pagamento.

TASK-002 non aggiunge networking, modello commerciale o dati reali.

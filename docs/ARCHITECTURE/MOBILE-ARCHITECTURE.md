# Mobile architecture

## Stack

- Flutter e Dart stable;
- Android Kotlin e iOS Swift;
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

TASK-001 non crea interfacce o livelli vuoti. La shell e la configurazione sono
responsabilità concrete; repository e ViewModel verranno introdotti insieme alle feature.

## Avvio

`main.dart` delega a `bootstrap.dart`. Il bootstrap legge una configurazione compile-time,
valida l'ambiente, inizializza Supabase solo con URL e publishable key completi e avvia
`ProviderScope`.

In development senza configurazione l'app resta offline e usabile. In production una
configurazione incompleta è un errore esplicito.

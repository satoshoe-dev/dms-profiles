# Profiles: passo dopo passo

[English](GUIDE.md) · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · **Italiano** · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Installa e attiva il plugin

Dal registro dei plugin:

```sh
dms plugins install dmsProfiles
```

Si trova anche in DMS in Impostazioni → Plugin → Sfoglia. Oppure clona il repository nella cartella dei plugin di DMS:

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
```

Apri Impostazioni → Plugin e attiva Profiles.

![Elenco dei plugin con Profiles](images/01-plugin-list.png)

## 2. Crea il primo profilo

Configura la shell come preferisci: tema, colore di accento, sfondo, barra, cornice. Poi espandi Profiles nell'elenco dei plugin, inserisci un nome e fai clic su «Crea».

![Creazione di un profilo](images/02-create.png)

Il nuovo profilo è subito attivo. Tutto ciò che modifichi in seguito viene salvato al suo interno dopo pochi secondi.

## 3. Creane un secondo

Cambia l'aspetto, per esempio con un altro sfondo e un altro colore di accento, e crea un secondo profilo allo stesso modo. Ora le modifiche finiscono nel secondo profilo, mentre il primo resta com'era.

## 4. Aggiungi una scorciatoia per il selettore

In niri, aggiungi alla configurazione:

```kdl
binds {
    Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
}
```

## 5. Cambia profilo

Premi la scorciatoia, scegli un profilo con la rotella del mouse o i tasti freccia e premi Invio oppure fai clic sul profilo.

![Il selettore come carosello](images/03-picker-carousel.png)

Lo schermo si ferma per un attimo mentre viene catturato. Poi la transizione passa allo sfondo del nuovo profilo, e barre, cornice, finestre e widget compaiono in dissolvenza appena DMS ha applicato il profilo. Se un profilo non ha uno sfondo proprio, la transizione scopre invece il desktop già pronto.

![Una transizione in corso](images/04-transition.png)

## 6. Scegli l'aspetto del selettore

In «Selettore dei profili» scegli la vista (fila, libera, carosello o griglia) e la forma delle anteprime.

![Impostazioni del selettore](images/05-picker-settings.png)

![La griglia con esagoni](images/06-picker-grid.png)

## 7. Scegli la transizione

In «Transizione» scegli un tipo oppure lascia «Casuale». Con Casuale, fai clic sui tipi che vuoi consentire. «Durata» stabilisce quanto dura l'animazione, 1200 ms di default. «Prova la transizione» riproduce l'animazione una volta senza cambiare profilo, mostrando in grigio l'immagine precedente.

![Impostazioni della transizione](images/07-transition-settings.png)

## 8. Gestisci i profili

L'elenco in cima alle impostazioni del plugin ha i pulsanti per applicare, rinominare, spostare in su o in giù ed eliminare un profilo. Il pulsante per annullare accanto al profilo attivo ripristina lo stato che aveva al momento dell'attivazione. La riga della cartella sotto il nome di ogni profilo imposta la cartella in cui si apre il selettore degli sfondi (`dms ipc call profiles wallpapers`): clic per sceglierla, la croce accanto la rimuove.

![Elenco dei profili](images/08-list.png)

## 9. Impostazioni dei plugin in un profilo (facoltativo)

Per mantenere le impostazioni di un altro plugin per ogni profilo, inserisci il suo id in «Plugin salvati con il profilo», per esempio `audioFx`.

## 10. Elementi esterni a DMS (facoltativo)

In «Avanzate» puoi impostare un comando di salvataggio e un comando di applicazione per le impostazioni che DMS non gestisce, come i colori del terminale. Nel README trovi cosa ricevono e un esempio.

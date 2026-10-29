# Profiles

[English](README.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · **Italiano** · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

Un plugin per [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) che salva l'aspetto della tua shell con un nome e ti permette di passare da un aspetto all'altro. Un profilo contiene il tema e il colore d'accento, la modalità chiara o scura, lo sfondo, le tue barre, la cornice, la trasparenza, i caratteri, le animazioni e i widget del desktop con le loro posizioni.

![Profiles](assets/screenshot.png)

Passo per passo con immagini: [guida all'installazione e alla configurazione](docs/GUIDE.it.md).

## Cambio di profilo

Apri il selettore con una scorciatoia da tastiera e scegli un profilo. Lo schermo si ferma per un attimo (circa 0,2 s) mentre viene catturato. Poi la transizione passa subito dall'immagine precedente allo sfondo del nuovo profilo. Nel frattempo DMS applica il profilo, e quando è pronto barre, cornice, finestre e widget compaiono in dissolvenza sopra il nuovo sfondo. Non si vede la shell cambiare pezzo per pezzo.

I profili senza uno sfondo proprio usano la sequenza precedente: l'immagine catturata resta finché il profilo è applicato, poi la transizione scopre il desktop già pronto. La durata della transizione si imposta nelle impostazioni (1,2 s di default).

Puoi scegliere fra 29 transizioni, tra cui dissolvenza, tendina, cerchio, porte, veneziane, scioglimento, frantumi, un CRT che si spegne, neve e cinque effetti hack. La modalità Casuale si può limitare a quelle che preferisci. Nella maggior parte delle animazioni il bordo si illumina con il colore d'accento del nuovo profilo.

## Selettore

Il selettore ha quattro viste: una fila su un pannello, la stessa fila senza pannello, un carosello con il profilo attuale grande al centro e una griglia che riempie lo schermo. Le anteprime possono essere verticali, orizzontali, quadrate, circolari, esagonali, a rombo o inclinate (verticali con la cornice inclinata). Nella griglia, esagoni e rombi sono disposti a nido d'ape con la stessa distanza delle tue finestre. Contorno, bagliore, spunta e raggio degli angoli si possono disattivare o regolare.

La rotella del mouse e i tasti freccia spostano la selezione, Invio o un clic la applica, Esc chiude il selettore.

## Salvataggio

Le modifiche che fai nelle impostazioni di DMS vengono salvate nel profilo attivo dopo pochi secondi. Ogni profilo ricorda com'era quando è stato attivato, quindi puoi annullare le modifiche dalla pagina delle impostazioni. Lo sfondo viene copiato nel profilo, per cui spostare o eliminare il file originale non lo rovina.

I profili si trovano in `~/.config/DankMaterialShell/profiles/`, una cartella per profilo.

## Impostazioni di altri plugin

Anche le impostazioni dei plugin possono far parte di un profilo. Inserisci gli ID dei plugin in Impostazioni → Plugin → Profiles → Plugin salvati con il profilo, per esempio `audioFx`.

## Cose fuori da DMS

Colori del terminale, temi del browser o regole del compositor che DMS non gestisce si possono coprire con due comandi facoltativi:

- Il comando di salvataggio viene eseguito quando si salva un profilo. Il JSON che stampa viene memorizzato nel profilo come `extras`.
- Il comando di applicazione viene eseguito durante il cambio, subito dopo la scrittura delle nuove impostazioni. Il nuovo desktop compare solo quando ha finito. Riceve `DMS_PROFILE_DIR`, `DMS_PROFILE_SLUG`, `DMS_PROFILE_NAME` e `DMS_PROFILE_NEW_COLORS` (1 se vengono generati nuovi colori). Il file del profilo è `$DMS_PROFILE_DIR/profile.json`.

Un piccolo esempio che conserva il carattere dell'interfaccia GTK per ogni profilo:

```sh
# save command
printf '{"font": "%s"}' "$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")"

# apply command
gsettings set org.gnome.desktop.interface font-name \
  "$(python3 -c 'import json,os; print(json.load(open(os.environ["DMS_PROFILE_DIR"] + "/profile.json"))["extras"]["font"])')"
```

## Requisiti

DankMaterialShell 1.6.1 o successivo. Per la transizione lo schermo viene catturato con `grim`, se installato, altrimenti con `dms screenshot`, incluso in DMS. Io uso il plugin su niri. Spaziatura delle finestre, raggio degli angoli e spessore del bordo vengono scritti da DMS stesso nella configurazione del compositor, quindi dovrebbero seguire il profilo anche sugli altri compositor supportati da DMS.

## Installazione

Dal registro dei plugin:

```sh
dms plugins install dmsProfiles
dms ipc call plugins enable dmsProfiles
```

Si trova anche in DMS in Impostazioni → Plugin → Sfoglia. Per installarlo dal repository:

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
dms ipc call plugins enable dmsProfiles
```

Poi aggiungi una scorciatoia da tastiera, per esempio in niri:

```kdl
Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
```

## IPC

```sh
dms ipc call profiles toggle
dms ipc call profiles list
dms ipc call profiles apply <slug>
dms ipc call profiles create <name>
dms ipc call profiles save
dms ipc call profiles rename <slug> <new name>
dms ipc call profiles remove <slug>
dms ipc call profiles move <slug> left|right|<position>
dms ipc call profiles reset <slug>
dms ipc call profiles previewTransition <type>
dms ipc call profiles status
```

## Traduzioni

Il plugin è disponibile in tedesco, spagnolo, francese, italiano, portoghese, russo, giapponese e cinese semplificato e segue la lingua impostata in DMS. Se una traduzione suona male, una pull request è benvenuta.

## Nota

Ho scritto questo plugin con l'aiuto di Claude (Anthropic) e lo uso ogni giorno sul mio desktop.

## Licenza

[MIT](LICENSE)

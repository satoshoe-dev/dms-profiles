# Profiles

[English](README.md) · **Deutsch** · [Español](README.es.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

Ein Plugin für [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell), das die Optik der Shell unter einem Namen speichert und zwischen diesen Optiken wechseln lässt. Ein Profil enthält Theme und Akzentfarbe, hellen oder dunklen Modus, das Hintergrundbild, die Leisten, den Rahmen, Transparenz, Schriften, Animationen und Desktop-Widgets samt ihrer Position.

![Profiles](assets/screenshot.png)

Schritt für Schritt mit Bildern: [Anleitung zu Installation und Einrichtung](docs/GUIDE.de.md).

## Wechseln

Die Profilauswahl öffnet sich per Tastenkombination, dort wählt man ein Profil. Der Bildschirm wird kurz festgehalten (etwa 0,2 s), solange er aufgenommen wird. Dann läuft der Übergang sofort vom alten Bild auf das Hintergrundbild des neuen Profils. Währenddessen wendet DMS das Profil an, und sobald es fertig ist, blenden Leisten, Rahmen, Fenster und Widgets über dem neuen Hintergrund ein. Dass sich die Shell Stück für Stück umbaut, sieht man nicht.

Profile ohne eigenes Hintergrundbild nutzen den bisherigen Ablauf: Das aufgenommene Bild bleibt stehen, bis das Profil angewendet ist, und der Übergang deckt dann den fertigen Desktop auf. Die Dauer des Übergangs lässt sich in den Einstellungen festlegen (Standard 1,2 s).

Zur Wahl stehen 29 Übergänge, darunter Überblenden, Wischen, Kreis, Türen, Jalousie, Schmelzen, Splitter, eine abschaltende Bildröhre, ein Schneesturm und fünf Hack-Effekte. Zufällig lässt sich auf die Übergänge beschränken, die einem gefallen. Bei den meisten Animationen leuchtet die Kante in der Akzentfarbe des neuen Profils.

## Profilauswahl

Die Auswahl gibt es in vier Ansichten: eine Leiste mit Rahmen, dieselbe Leiste frei ohne Rahmen, ein Karussell mit dem aktuellen Profil groß in der Mitte und Kacheln über den ganzen Bildschirm. Die Vorschaubilder können hochkant, quer, quadratisch, rund, sechseckig oder rautenförmig sein. In der Kachelansicht liegen Sechsecke und Rauten als Waben, mit demselben Abstand wie die Fenster. Rahmen, Leuchten, Haken und Eckenradius lassen sich abschalten oder anpassen.

Mausrad und Pfeiltasten bewegen die Auswahl, Enter oder ein Klick wendet das Profil an, Escape schließt die Auswahl.

## Speichern

Änderungen in den DMS-Einstellungen landen nach ein paar Sekunden im aktiven Profil. Jedes Profil merkt sich, wie es beim Aktivieren aussah, daher lassen sich die Änderungen auf der Einstellungsseite zurücknehmen. Das Hintergrundbild wird ins Profil kopiert. Wird die Originaldatei verschoben oder gelöscht, bleibt das Profil also intakt. Solange die Originaldatei existiert, zeigt der Wechsel das Original und nicht die Kopie, sodass das Hintergrundbild in seinem eigenen Ordner bleibt (der Hintergrundwechsel von DMS und andere Plugins sehen den ganzen Ordner). Die Kopie wird verwendet, wenn die Datei fehlt. Mit „Originaldatei des Hintergrundbilds verwenden“ in den Einstellungen lässt sich das abschalten.

## Hintergrundauswahl

`dms ipc call profiles wallpapers` öffnet dieselbe Auswahl mit den Bildern eines Hintergrundordners. Eingabe oder ein Klick setzt eines; das automatische Speichern legt es im aktiven Profil ab. Sie nutzt die Ansicht und Form, die du für Profile gewählt hast.

Standardmäßig ist das der Ordner des aktuellen Hintergrundbilds. Ein Profil kann stattdessen einen eigenen Hintergrundordner haben, sodass die Auswahl immer dort öffnet, auch wenn das aktuelle Bild von woanders stammt: Er wird mit einem Klick auf die Ordnerzeile unter dem Profilnamen in den Einstellungen (das Kreuz entfernt ihn) oder mit `dms ipc call profiles folder <slug> /pfad/zu/bildern` gesetzt (ein leerer Pfad entfernt ihn). Gespeichert wird er als `wallpaperFolder` in der `profile.json` des Profils.

Profile liegen in `~/.config/DankMaterialShell/profiles/`, ein Ordner pro Profil.

## Einstellungen anderer Plugins

Auch Plugin-Einstellungen können zu einem Profil gehören. Dazu die Plugin-IDs unter Einstellungen → Plugins → Profiles → Im Profil mitgespeicherte Plugins eintragen, zum Beispiel `audioFx`.

## Dinge außerhalb von DMS

Terminalfarben, Browser-Themes oder Compositor-Regeln, um die sich DMS nicht kümmert, lassen sich mit zwei optionalen Befehlen abdecken:

- Der Befehl beim Speichern läuft, wenn ein Profil gespeichert wird. Das JSON, das er ausgibt, landet im Profil unter `extras`.
- Der Befehl beim Anwenden läuft während des Wechsels, direkt nachdem die neuen Einstellungen geschrieben sind. Der neue Desktop erscheint erst, wenn er fertig ist. Er bekommt `DMS_PROFILE_DIR`, `DMS_PROFILE_SLUG`, `DMS_PROFILE_NAME` und `DMS_PROFILE_NEW_COLORS` (1, wenn neue Farben erzeugt werden). Die Profildatei ist `$DMS_PROFILE_DIR/profile.json`.

Ein kleines Beispiel, das die GTK-Oberflächenschrift je Profil festhält:

```sh
# save command
printf '{"font": "%s"}' "$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")"

# apply command
gsettings set org.gnome.desktop.interface font-name \
  "$(python3 -c 'import json,os; print(json.load(open(os.environ["DMS_PROFILE_DIR"] + "/profile.json"))["extras"]["font"])')"
```

## Voraussetzungen

DankMaterialShell 1.6.1 oder neuer. Für den Übergang wird der Bildschirm mit `grim` aufgenommen, wenn es installiert ist, sonst mit `dms screenshot`, das bei DMS dabei ist. Ich nutze das Plugin unter niri. Fensterabstände, Eckenradius und Rahmenbreite schreibt DMS selbst in die Compositor-Konfiguration, daher sollten sie auch auf anderen von DMS unterstützten Compositors dem Profil folgen.

## Installation

Aus der Plugin-Registry:

```sh
dms plugins install dmsProfiles
dms ipc call plugins enable dmsProfiles
```

Das Plugin steht auch in DMS unter Einstellungen → Plugins → Durchsuchen. Oder direkt aus dem Repository:

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
dms ipc call plugins enable dmsProfiles
```

Danach eine Tastenkombination anlegen, zum Beispiel in niri:

```kdl
Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
```

## IPC

```sh
dms ipc call profiles toggle
dms ipc call profiles wallpapers
dms ipc call profiles folder <slug> <path>
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

## Übersetzungen

Das Plugin gibt es auf Deutsch, Spanisch, Französisch, Italienisch, Portugiesisch, Russisch, Japanisch und vereinfachtem Chinesisch. Es folgt der Sprache, die in DMS eingestellt ist. Liest sich eine Übersetzung falsch, ist ein Pull Request willkommen.

## Hinweis

Ich habe dieses Plugin mit Hilfe von Claude (Anthropic) geschrieben und nutze es jeden Tag auf meinem eigenen Desktop.

## Lizenz

[MIT](LICENSE)

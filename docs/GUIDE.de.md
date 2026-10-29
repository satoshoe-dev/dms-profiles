# Profiles: Schritt für Schritt

[English](GUIDE.md) · **Deutsch** · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Plugin installieren und einschalten

Aus der Plugin-Registry:

```sh
dms plugins install dmsProfiles
```

Das Plugin steht auch in DMS unter Einstellungen → Plugins → Durchsuchen. Oder klone das Repository in deinen DMS-Plugin-Ordner:

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
```

Öffne Einstellungen → Plugins und schalte Profiles ein.

![Plugin-Liste mit Profiles](images/01-plugin-list.png)

## 2. Erstes Profil anlegen

Richte die Shell so ein, wie sie dir gefällt: Theme, Akzentfarbe, Hintergrundbild, Leiste, Rahmen. Klappe dann Profiles in der Plugin-Liste auf, gib einen Namen ein und klicke auf „Anlegen“.

![Ein Profil anlegen](images/02-create.png)

Das neue Profil ist sofort aktiv. Alles, was du danach änderst, wird nach wenigen Sekunden darin gespeichert.

## 3. Ein zweites anlegen

Ändere die Optik, zum Beispiel mit einem anderen Hintergrundbild und einer anderen Akzentfarbe, und lege auf dieselbe Weise ein zweites Profil an. Änderungen landen jetzt im zweiten Profil, das erste bleibt, wie es war.

## 4. Tastenkombination für die Auswahl einrichten

Füge in niri deiner Konfiguration hinzu:

```kdl
binds {
    Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
}
```

## 5. Wechseln

Drücke die Tastenkombination, wähle mit dem Mausrad oder den Pfeiltasten ein Profil und drücke Enter oder klicke es an.

![Die Auswahl als Karussell](images/03-picker-carousel.png)

Der Bildschirm steht kurz still, solange er aufgenommen wird. Dann läuft der Übergang auf das Hintergrundbild des neuen Profils, und Leisten, Rahmen, Fenster und Widgets blenden ein, sobald DMS das Profil angewendet hat. Hat ein Profil kein eigenes Hintergrundbild, deckt der Übergang stattdessen den fertigen Desktop auf.

![Ein Übergang läuft](images/04-transition.png)

## 6. Aussehen der Auswahl festlegen

Wähle unter „Profilauswahl“ die Ansicht (Leiste, frei, Karussell oder Kacheln) und die Form der Vorschaubilder.

![Einstellungen der Auswahl](images/05-picker-settings.png)

![Die Kacheln mit Sechsecken](images/06-picker-grid.png)

## 7. Übergang wählen

Wähle unter „Übergang beim Wechsel“ eine Art oder lass ihn auf „Zufällig“. Bei Zufällig klickst du die Arten an, die erlaubt sein sollen. „Dauer“ legt fest, wie lange die Animation läuft, Standard sind 1200 ms. „Ausprobieren“ spielt die Animation einmal ab, ohne zu wechseln, und zeigt das alte Bild dabei grau.

![Einstellungen für den Übergang](images/07-transition-settings.png)

## 8. Profile verwalten

Die Liste oben in den Plugin-Einstellungen hat Schaltflächen, um ein Profil anzuwenden, umzubenennen, nach oben oder unten zu verschieben und zu löschen. Die Schaltfläche zum Rückgängigmachen neben dem aktiven Profil stellt den Zustand wieder her, den es beim Aktivieren hatte. Die Ordnerzeile unter jedem Profilnamen legt den Ordner fest, in dem die Hintergrundauswahl (`dms ipc call profiles wallpapers`) öffnet: Klick zum Wählen, das Kreuz daneben entfernt ihn.

![Profilliste](images/08-list.png)

## 9. Plugin-Einstellungen im Profil (optional)

Um die Einstellungen eines anderen Plugins je Profil zu behalten, trage seine ID unter „Im Profil mitgespeicherte Plugins“ ein, zum Beispiel `audioFx`.

## 10. Dinge außerhalb von DMS (optional)

Unter „Erweitert“ kannst du einen Befehl beim Speichern und einen Befehl beim Anwenden festlegen, für Einstellungen, die DMS nicht verwaltet, etwa Terminalfarben. Was sie übergeben bekommen, und ein Beispiel stehen in der README.

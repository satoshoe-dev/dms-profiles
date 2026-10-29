# Profiles: step by step

**English** · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Install and enable the plugin

From the plugin registry:

```sh
dms plugins install dmsProfiles
```

It is also listed in DMS under Settings → Plugins → Browse. Or clone the repository into your DMS plugin folder:

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
```

Open Settings → Plugins and switch Profiles on.

![Plugin list with Profiles](images/01-plugin-list.png)

## 2. Create your first profile

Set up the shell the way you like it: theme, accent color, wallpaper, bar, frame. Then expand Profiles in the plugin list, type a name and click "Create".

![Creating a profile](images/02-create.png)

The new profile is active right away. Everything you change afterwards is saved into it after a few seconds.

## 3. Create a second one

Change the look, for example another wallpaper and accent color, and create a second profile the same way. Changes now go into the second profile, the first one stays as it was.

## 4. Add a keybind for the picker

In niri, add to your config:

```kdl
binds {
    Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
}
```

## 5. Switch

Press the keybind, choose a profile with the mouse wheel or the arrow keys and press Enter or click it.

![The picker as a carousel](images/03-picker-carousel.png)

The screen stands still for a moment while it is captured. Then the transition runs onto the wallpaper of the new profile, and bars, frame, windows and widgets fade in once DMS has applied the profile. If a profile has no wallpaper of its own, the transition reveals the finished desktop instead.

![A transition in progress](images/04-transition.png)

## 6. Choose how the picker looks

Under "Profile picker" choose the view (strip, free, carousel or grid) and the shape of the previews.

![Picker settings](images/05-picker-settings.png)

![The grid with hexagons](images/06-picker-grid.png)

## 7. Choose the transition

Under "Transition" pick a type or leave it on "Random". With Random, click the types you want to allow. "Duration" sets how long the animation runs, 1200 ms by default. "Preview transition" plays the animation once without switching, with the old picture shown in gray.

![Transition settings](images/07-transition-settings.png)

## 8. Manage profiles

The list at the top of the plugin settings has buttons to apply, rename, move up or down and delete a profile. The undo button next to the active profile brings back the state it had when it was activated. The folder line under each profile name sets the folder where the wallpaper picker (`dms ipc call profiles wallpapers`) opens: click to choose one, the cross next to it removes it.

![Profile list](images/08-list.png)

## 9. Plugin settings in a profile (optional)

To keep the settings of another plugin per profile, enter its id under "Plugins saved with a profile", for example `audioFx`.

## 10. Things outside DMS (optional)

Under "Advanced" you can set a save command and an apply command for settings DMS does not manage, such as terminal colors. See the README for what they receive and an example.

# Profiles

**English** · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

A plugin for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) that saves the look of your shell under a name and lets you switch between these looks. A profile holds the theme and accent color, light or dark mode, the wallpaper, your bars, the frame, transparency, fonts, animations and desktop widgets with their positions.

![Profiles](assets/screenshot.png)

Step by step with pictures: [installation and setup guide](docs/GUIDE.md).

## Switching

Open the picker with a keybind and choose a profile. The screen is held still for a moment (about 0.2 s) while it is captured. Then the transition runs right away from the old picture onto the wallpaper of the new profile. DMS applies the profile in the meantime, and bars, frame, windows and widgets fade in over the new wallpaper once it is ready. You never see the shell change piece by piece.

Profiles without a wallpaper of their own use the older sequence: the captured picture stays until the profile is applied, and the transition then reveals the finished desktop. The duration of the transition can be set in the settings (1.2 s by default).

There are 29 transitions to choose from, among them fade, wipe, circle, doors, blinds, melt, shatter, a CRT switching off, a snowstorm and five glitch effects. Random mode can be limited to the ones you like. The edge of most animations glows in the accent color of the new profile.

## Picker

The picker comes in four views: a strip on a panel, the same strip without the panel, a carousel with the current profile large in the middle, and a grid that fills the screen. Previews can be portrait, landscape, square, circle, hexagon, diamond or skewed (a portrait card with a slanted frame). In the grid, hexagons and diamonds are laid out as a honeycomb with the same gap as your windows. Outline, glow, check mark and corner radius can be turned off or adjusted.

Mouse wheel and arrow keys move the selection, Enter or a click applies it, Escape closes the picker.

## Saving

Changes you make in the DMS settings are saved into the active profile after a few seconds. Each profile remembers how it looked when it was activated, so you can undo your changes from the settings page. The wallpaper is copied into the profile, so moving or deleting the original file does not break it.

Profiles live in `~/.config/DankMaterialShell/profiles/`, one folder per profile.

## Settings of other plugins

Plugin settings can be part of a profile as well. Enter the plugin ids under Settings → Plugins → Profiles → Plugins saved with a profile, for example `audioFx`.

## Things outside DMS

Terminal colors, browser themes or compositor rules that DMS does not manage can be handled with two optional commands:

- The save command runs when a profile is saved. Whatever JSON it prints is stored in the profile as `extras`.
- The apply command runs while switching, right after the new settings have been written. The new desktop is shown only after it has finished. It gets `DMS_PROFILE_DIR`, `DMS_PROFILE_SLUG`, `DMS_PROFILE_NAME` and `DMS_PROFILE_NEW_COLORS` (1 if new colors are being generated). The profile file is `$DMS_PROFILE_DIR/profile.json`.

A small example that keeps the GTK interface font per profile:

```sh
# save command
printf '{"font": "%s"}' "$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")"

# apply command
gsettings set org.gnome.desktop.interface font-name \
  "$(python3 -c 'import json,os; print(json.load(open(os.environ["DMS_PROFILE_DIR"] + "/profile.json"))["extras"]["font"])')"
```

## Requirements

DankMaterialShell 1.6.1 or newer, tested with 1.6.2 and 2.0.0. Profiles saved under 1.6 are converted on the first start under 2.0; the original stays next to each profile as `profile.v18.json`. For the transition the screen is captured with `grim` if it is installed, otherwise with `dms screenshot`, which comes with DMS. I use the plugin on niri. Window gaps, corner radius and border width are written to the compositor config by DMS itself, so they should follow a profile on other compositors DMS supports as well.

## Installation

From the plugin registry:

```sh
dms plugins install dmsProfiles
dms ipc call plugins enable dmsProfiles
```

It is also listed in DMS under Settings → Plugins → Browse. To install from the repository instead:

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
dms ipc call plugins enable dmsProfiles
```

Then add a keybind, for example in niri:

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

## Translations

The plugin is available in German, Spanish, French, Italian, Portuguese, Russian, Japanese and Simplified Chinese and follows the language set in DMS. If a translation reads wrong, a pull request is welcome.

## Note

I wrote this plugin with help from Claude (Anthropic) and use it every day on my own desktop.

## License

[MIT](LICENSE)

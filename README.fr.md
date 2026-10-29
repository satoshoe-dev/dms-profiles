# Profiles

[English](README.md) · [Deutsch](README.de.md) · [Español](README.es.md) · **Français** · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

Un plugin pour [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) qui enregistre l'apparence de votre shell sous un nom et permet de passer d'une apparence à l'autre. Un profil contient le thème et la couleur d'accent, le mode clair ou sombre, le fond d'écran, vos barres, le cadre, la transparence, les polices, les animations et les widgets du bureau avec leur position.

![Profiles](assets/screenshot.png)

Pas à pas avec des images : [guide d'installation et de configuration](docs/GUIDE.fr.md).

## Changer de profil

Ouvrez le sélecteur avec un raccourci clavier et choisissez un profil. L'écran s'arrête un instant (environ 0,2 s) pendant sa capture. La transition passe ensuite tout de suite de l'ancienne image au fond d'écran du nouveau profil. Pendant ce temps, DMS applique le profil, et dès qu'il est prêt, barres, cadre, fenêtres et widgets apparaissent en fondu sur le nouveau fond. On ne voit pas le shell changer morceau par morceau.

Les profils sans fond d'écran propre suivent l'ancien déroulement : l'image capturée reste affichée jusqu'à ce que le profil soit appliqué, puis la transition dévoile le bureau terminé. La durée de la transition se règle dans les paramètres (1,2 s par défaut).

Vous avez le choix entre 29 transitions, dont fondu, balayage, cercle, portes, stores, fusion, éclats, un écran CRT qui s'éteint, de la neige et cinq effets de hack. Le mode Aléatoire peut se limiter à celles que vous aimez. Sur la plupart des animations, le bord brille dans la couleur d'accent du nouveau profil.

## Sélecteur

Le sélecteur propose quatre affichages : une rangée sur un panneau, la même rangée sans panneau, un carrousel avec le profil actuel en grand au centre, et une grille qui remplit l'écran. Les aperçus peuvent être en portrait, en paysage, carrés, ronds, hexagonaux ou en losange. Dans la grille, les hexagones et les losanges sont disposés en nid d'abeille, avec le même espacement que vos fenêtres. Le contour, le halo, la coche et le rayon des coins peuvent être désactivés ou réglés.

La molette de la souris et les flèches déplacent la sélection, Entrée ou un clic l'applique, Échap ferme le sélecteur.

## Enregistrement

Les modifications faites dans les paramètres de DMS sont enregistrées dans le profil actif après quelques secondes. Chaque profil garde en mémoire son état au moment de l'activation, ce qui permet d'annuler les modifications depuis la page des paramètres. Le fond d'écran est copié dans le profil, donc déplacer ou supprimer le fichier d'origine ne le casse pas. Tant que le fichier d'origine existe, le changement de profil affiche l'original et non la copie, si bien que le fond d'écran reste dans son propre dossier (le défilement des fonds d'écran de DMS et les autres plugins voient tout le dossier). La copie sert quand le fichier a disparu. Désactivez cela avec « Utiliser le fichier d'origine du fond d'écran » dans les réglages.

## Sélecteur de fond d'écran

`dms ipc call profiles wallpapers` ouvre le même sélecteur avec les images d'un dossier de fonds d'écran. Entrée ou un clic en définit une ; l'enregistrement automatique la conserve dans le profil actif. Il utilise la vue et la forme du sélecteur choisies pour les profils.

Par défaut, c'est le dossier du fond d'écran actuel. Un profil peut avoir son propre dossier de fonds d'écran, pour que le sélecteur s'ouvre toujours là, même si l'image actuelle vient d'ailleurs : on le définit en cliquant sur la ligne de dossier sous le nom du profil dans les réglages (la croix le retire), ou avec `dms ipc call profiles folder <slug> /chemin/vers/images` (un chemin vide le retire). Il est enregistré sous `wallpaperFolder` dans le `profile.json` du profil.

Les profils se trouvent dans `~/.config/DankMaterialShell/profiles/`, un dossier par profil.

## Paramètres des autres plugins

Les paramètres de plugins peuvent aussi faire partie d'un profil. Saisissez les identifiants des plugins dans Paramètres → Plugins → Profiles → Plugins enregistrés avec le profil, par exemple `audioFx`.

## Ce qui est hors de DMS

Les couleurs du terminal, les thèmes du navigateur ou les règles du compositeur que DMS ne gère pas peuvent être pris en charge par deux commandes facultatives :

- La commande d'enregistrement s'exécute quand un profil est enregistré. Le JSON qu'elle affiche est stocké dans le profil sous `extras`.
- La commande d'application s'exécute pendant le changement, juste après l'écriture des nouveaux paramètres. Le nouveau bureau n'apparaît qu'une fois qu'elle a terminé. Elle reçoit `DMS_PROFILE_DIR`, `DMS_PROFILE_SLUG`, `DMS_PROFILE_NAME` et `DMS_PROFILE_NEW_COLORS` (1 si de nouvelles couleurs sont générées). Le fichier du profil est `$DMS_PROFILE_DIR/profile.json`.

Un petit exemple qui conserve la police de l'interface GTK pour chaque profil :

```sh
# save command
printf '{"font": "%s"}' "$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")"

# apply command
gsettings set org.gnome.desktop.interface font-name \
  "$(python3 -c 'import json,os; print(json.load(open(os.environ["DMS_PROFILE_DIR"] + "/profile.json"))["extras"]["font"])')"
```

## Prérequis

DankMaterialShell 1.6.1 ou plus récent. Pour la transition, l'écran est capturé avec `grim` s'il est installé, sinon avec `dms screenshot`, fourni avec DMS. J'utilise le plugin sous niri. L'espacement des fenêtres, le rayon des coins et la largeur de la bordure sont écrits par DMS lui-même dans la configuration du compositeur, ils devraient donc suivre le profil aussi sur les autres compositeurs pris en charge par DMS.

## Installation

Depuis le registre des plugins :

```sh
dms plugins install dmsProfiles
dms ipc call plugins enable dmsProfiles
```

Il figure aussi dans DMS sous Paramètres → Plugins → Parcourir. Pour l’installer depuis le dépôt :

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
dms ipc call plugins enable dmsProfiles
```

Ajoutez ensuite un raccourci clavier, par exemple dans niri :

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

## Traductions

Le plugin est disponible en allemand, espagnol, français, italien, portugais, russe, japonais et chinois simplifié, et suit la langue réglée dans DMS. Si une traduction sonne faux, une pull request est la bienvenue.

## Remarque

J'ai écrit ce plugin avec l'aide de Claude (Anthropic) et je l'utilise tous les jours sur mon propre bureau.

## Licence

[MIT](LICENSE)

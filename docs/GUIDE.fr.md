# Profiles : pas à pas

[English](GUIDE.md) · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · **Français** · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Installer et activer le plugin

Depuis le registre des plugins :

```sh
dms plugins install dmsProfiles
```

Il figure aussi dans DMS sous Paramètres → Plugins → Parcourir. Ou clonez le dépôt dans votre dossier de plugins DMS :

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
```

Ouvrez Paramètres → Plugins et activez Profiles.

![Liste des plugins avec Profiles](images/01-plugin-list.png)

## 2. Créer votre premier profil

Configurez le shell comme vous l'aimez : thème, couleur d'accentuation, fond d'écran, barre, cadre. Dépliez ensuite Profiles dans la liste des plugins, saisissez un nom et cliquez sur « Créer ».

![Création d'un profil](images/02-create.png)

Le nouveau profil est actif immédiatement. Tout ce que vous modifiez ensuite y est enregistré au bout de quelques secondes.

## 3. En créer un deuxième

Changez l'apparence, par exemple avec un autre fond d'écran et une autre couleur d'accentuation, puis créez un deuxième profil de la même façon. Les modifications vont désormais dans le deuxième profil, le premier reste tel qu'il était.

## 4. Ajouter un raccourci pour le sélecteur

Dans niri, ajoutez à votre configuration :

```kdl
binds {
    Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
}
```

## 5. Changer de profil

Appuyez sur le raccourci, choisissez un profil avec la molette de la souris ou les touches fléchées, puis appuyez sur Entrée ou cliquez dessus.

![Le sélecteur en carrousel](images/03-picker-carousel.png)

L'écran s'arrête un instant pendant sa capture. La transition passe ensuite au fond d'écran du nouveau profil, et barres, cadre, fenêtres et widgets apparaissent en fondu dès que DMS a appliqué le profil. Si un profil n'a pas de fond d'écran propre, la transition dévoile à la place le bureau terminé.

![Une transition en cours](images/04-transition.png)

## 6. Choisir l'apparence du sélecteur

Sous « Sélecteur de profils », choisissez l'affichage (rangée, libre, carrousel ou grille) et la forme des aperçus.

![Réglages du sélecteur](images/05-picker-settings.png)

![La grille avec des hexagones](images/06-picker-grid.png)

## 7. Choisir la transition

Sous « Transition », choisissez un type ou laissez « Aléatoire ». Avec Aléatoire, cliquez sur les types à autoriser. « Durée » règle la durée de l'animation, 1200 ms par défaut. « Tester la transition » joue l'animation une fois sans changer de profil, avec l'ancienne image affichée en gris.

![Réglages de la transition](images/07-transition-settings.png)

## 8. Gérer les profils

La liste en haut des réglages du plugin propose des boutons pour appliquer, renommer, monter, descendre et supprimer un profil. Le bouton d'annulation à côté du profil actif rétablit l'état qu'il avait lors de son activation. La ligne de dossier sous le nom de chaque profil définit le dossier où s'ouvre le sélecteur de fonds d'écran (`dms ipc call profiles wallpapers`) : clic pour le choisir, la croix à côté le retire.

![Liste des profils](images/08-list.png)

## 9. Réglages de plugins dans un profil (facultatif)

Pour conserver les réglages d'un autre plugin par profil, saisissez son identifiant sous « Plugins enregistrés avec le profil », par exemple `audioFx`.

## 10. Éléments hors de DMS (facultatif)

Sous « Avancé », vous pouvez définir une commande d'enregistrement et une commande d'application pour des réglages que DMS ne gère pas, comme les couleurs du terminal. Le README indique ce qu'elles reçoivent et donne un exemple.

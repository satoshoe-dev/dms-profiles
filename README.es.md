# Profiles

[English](README.md) · [Deutsch](README.de.md) · **Español** · [Français](README.fr.md) · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

Un complemento para [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) que guarda el aspecto de tu shell con un nombre y te permite cambiar entre esos aspectos. Un perfil incluye el tema y el color de acento, el modo claro u oscuro, el fondo de pantalla, tus barras, el marco, la transparencia, las fuentes, las animaciones y los widgets de escritorio con sus posiciones.

![Profiles](assets/screenshot.png)

Paso a paso con imágenes: [guía de instalación y configuración](docs/GUIDE.es.md).

## Cambiar de perfil

Abre el selector con un atajo de teclado y elige un perfil. La pantalla se detiene un momento (unos 0,2 s) mientras se captura. Luego la transición pasa enseguida de la imagen anterior al fondo de pantalla del nuevo perfil. Mientras tanto DMS aplica el perfil, y cuando termina, las barras, el marco, las ventanas y los widgets aparecen con un fundido sobre el nuevo fondo. No se ve cómo el shell cambia pieza a pieza.

Los perfiles sin fondo de pantalla propio usan el proceso anterior: la imagen capturada se queda hasta que el perfil está aplicado y después la transición descubre el escritorio ya listo. La duración de la transición se puede ajustar en los ajustes (1,2 s por defecto).

Hay 29 transiciones para elegir, entre ellas fundido, barrido, círculo, puertas, persianas, derretir, cristal roto, un CRT que se apaga, nieve y cinco efectos de hack. La opción Aleatoria se puede limitar a las que te gusten. En la mayoría de las animaciones, el borde brilla con el color de acento del nuevo perfil.

## Selector

El selector tiene cuatro vistas: una fila sobre un panel, la misma fila sin panel, un carrusel con el perfil actual en grande en el centro y una cuadrícula que llena la pantalla. Las vistas previas pueden ser verticales, horizontales, cuadradas, circulares, hexagonales, en rombo o inclinadas (verticales con el marco inclinado). En la cuadrícula, los hexágonos y los rombos se colocan como un panal, con la misma separación que tus ventanas. El contorno, el brillo, la marca y el radio de las esquinas se pueden desactivar o ajustar.

La rueda del ratón y las flechas mueven la selección, Intro o un clic la aplica y Escape cierra el selector.

## Guardado

Los cambios que haces en los ajustes de DMS se guardan en el perfil activo después de unos segundos. Cada perfil recuerda cómo era al activarse, así que puedes deshacer tus cambios desde la página de ajustes. El fondo de pantalla se copia dentro del perfil, así que mover o borrar el archivo original no lo rompe.

Los perfiles están en `~/.config/DankMaterialShell/profiles/`, una carpeta por perfil.

## Ajustes de otros complementos

Los ajustes de los complementos también pueden formar parte de un perfil. Escribe los IDs de los complementos en Ajustes → Complementos → Profiles → Complementos guardados con el perfil, por ejemplo `audioFx`.

## Cosas fuera de DMS

Los colores del terminal, los temas del navegador o las reglas del compositor que DMS no gestiona se pueden cubrir con dos comandos opcionales:

- El comando al guardar se ejecuta cuando se guarda un perfil. El JSON que imprima se guarda en el perfil como `extras`.
- El comando al aplicar se ejecuta durante el cambio, justo después de escribir los nuevos ajustes. El nuevo escritorio no aparece hasta que termina. Recibe `DMS_PROFILE_DIR`, `DMS_PROFILE_SLUG`, `DMS_PROFILE_NAME` y `DMS_PROFILE_NEW_COLORS` (1 si se están generando colores nuevos). El archivo del perfil es `$DMS_PROFILE_DIR/profile.json`.

Un ejemplo pequeño que guarda la fuente de la interfaz GTK para cada perfil:

```sh
# save command
printf '{"font": "%s"}' "$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")"

# apply command
gsettings set org.gnome.desktop.interface font-name \
  "$(python3 -c 'import json,os; print(json.load(open(os.environ["DMS_PROFILE_DIR"] + "/profile.json"))["extras"]["font"])')"
```

## Requisitos

DankMaterialShell 1.6.1 o posterior. Para la transición, la pantalla se captura con `grim` si está instalado y, si no, con `dms screenshot`, que viene con DMS. Yo uso el complemento en niri. La separación entre ventanas, el radio de las esquinas y el ancho del borde los escribe el propio DMS en la configuración del compositor, así que deberían seguir al perfil también en otros compositores compatibles con DMS.

## Instalación

Desde el registro de complementos:

```sh
dms plugins install dmsProfiles
dms ipc call plugins enable dmsProfiles
```

También aparece en DMS en Ajustes → Complementos → Explorar. Para instalarlo desde el repositorio:

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
dms ipc call plugins enable dmsProfiles
```

Después añade un atajo de teclado, por ejemplo en niri:

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

## Traducciones

El complemento está disponible en alemán, español, francés, italiano, portugués, ruso, japonés y chino simplificado, y sigue el idioma configurado en DMS. Si una traducción suena mal, un pull request es bienvenido.

## Nota

Escribí este complemento con ayuda de Claude (Anthropic) y lo uso todos los días en mi propio escritorio.

## Licencia

[MIT](LICENSE)

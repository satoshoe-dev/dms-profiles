# Profiles: paso a paso

[English](GUIDE.md) · [Deutsch](GUIDE.de.md) · **Español** · [Français](GUIDE.fr.md) · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Instala y activa el complemento

Desde el registro de complementos:

```sh
dms plugins install dmsProfiles
```

También aparece en DMS en Ajustes → Complementos → Explorar. O clona el repositorio en tu carpeta de complementos de DMS:

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
```

Abre Ajustes → Complementos y activa Profiles.

![Lista de complementos con Profiles](images/01-plugin-list.png)

## 2. Crea tu primer perfil

Configura el shell a tu gusto: tema, color de acento, fondo de pantalla, barra, marco. Después despliega Profiles en la lista de complementos, escribe un nombre y haz clic en «Crear».

![Creando un perfil](images/02-create.png)

El perfil nuevo queda activo de inmediato. Todo lo que cambies después se guarda en él al cabo de unos segundos.

## 3. Crea un segundo perfil

Cambia el aspecto, por ejemplo con otro fondo de pantalla y otro color de acento, y crea un segundo perfil de la misma manera. Ahora los cambios van al segundo perfil y el primero se queda como estaba.

## 4. Añade un atajo para el selector

En niri, añade a tu configuración:

```kdl
binds {
    Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
}
```

## 5. Cambia de perfil

Pulsa el atajo, elige un perfil con la rueda del ratón o las teclas de flecha y pulsa Intro o haz clic en él.

![El selector como carrusel](images/03-picker-carousel.png)

La pantalla se detiene un momento mientras se captura. Luego la transición pasa al fondo de pantalla del nuevo perfil, y las barras, el marco, las ventanas y los widgets aparecen con un fundido en cuanto DMS ha aplicado el perfil. Si un perfil no tiene fondo propio, la transición descubre en su lugar el escritorio ya listo.

![Una transición en curso](images/04-transition.png)

## 6. Elige el aspecto del selector

En «Selector de perfiles», elige la vista (fila, libre, carrusel o cuadrícula) y la forma de las vistas previas.

![Ajustes del selector](images/05-picker-settings.png)

![La cuadrícula con hexágonos](images/06-picker-grid.png)

## 7. Elige la transición

En «Transición», elige un tipo o déjala en «Aleatoria». Con Aleatoria, haz clic en los tipos que quieras permitir. «Duración» fija cuánto dura la animación, 1200 ms por defecto. «Probar transición» reproduce la animación una vez sin cambiar de perfil y muestra la imagen anterior en gris.

![Ajustes de la transición](images/07-transition-settings.png)

## 8. Gestiona los perfiles

La lista de la parte superior de los ajustes del complemento tiene botones para aplicar, renombrar, subir, bajar y eliminar un perfil. El botón de deshacer junto al perfil activo recupera el estado que tenía cuando se activó. La línea de carpeta bajo el nombre de cada perfil define la carpeta en la que se abre el selector de fondos (`dms ipc call profiles wallpapers`): clic para elegirla, la cruz junto a ella la quita.

![Lista de perfiles](images/08-list.png)

## 9. Ajustes de complementos en un perfil (opcional)

Para guardar los ajustes de otro complemento por perfil, escribe su id en «Complementos guardados con el perfil», por ejemplo `audioFx`.

## 10. Cosas fuera de DMS (opcional)

En «Avanzado» puedes definir un comando al guardar y un comando al aplicar para ajustes que DMS no gestiona, como los colores de la terminal. En el README se explica qué reciben y hay un ejemplo.

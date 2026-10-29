// The settings page runs in its own component, separate from the daemon, so it
// talks to the daemon through `dms ipc call profiles ...`.

pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Modals.FileBrowser
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "dmsProfiles"

    property var profiles: []
    property string renameSlug: ""
    property string deleteSlug: ""
    property string folderTarget: ""

    // Dragging a row to change the order. While dragging, the other rows
    // already make room, so the drop position is visible.
    readonly property int rowHeight: 64
    readonly property int rowGap: Theme.spacingXS
    property string dragSlug: ""
    property int dragFrom: -1
    property int dropIndex: -1
    property real dragY: 0

    // Order as shown: the dragged profile already sits where it will land
    readonly property var displayOrder: {
        const slugs = root.profiles.map(p => p.slug);
        if (root.dragSlug === "" || root.dropIndex < 0)
            return slugs;
        const rest = slugs.filter(s => s !== root.dragSlug);
        rest.splice(root.dropIndex, 0, root.dragSlug);
        return rest;
    }

    function beginDrag(slug, index, y) {
        root.renameSlug = "";
        root.deleteSlug = "";
        root.dragSlug = slug;
        root.dragFrom = index;
        root.dropIndex = index;
        root.dragY = y;
    }

    function moveDrag(y) {
        const step = root.rowHeight + root.rowGap;
        root.dragY = Math.max(-step / 2, Math.min((root.profiles.length - 0.5) * step, y));
        root.dropIndex = Math.max(0, Math.min(root.profiles.length - 1, Math.round(root.dragY / step)));
    }

    function endDrag() {
        const slug = root.dragSlug;
        const to = root.dropIndex;
        const from = root.dragFrom;
        if (slug === "")
            return;
        const moved = to >= 0 && to !== from;
        if (moved) {
            // keep the new order on screen, the daemon only confirms it
            const list = root.profiles.slice();
            list.splice(to, 0, list.splice(from, 1)[0]);
            root.profiles = list;
        }
        root.dragSlug = "";
        root.dragFrom = -1;
        root.dropIndex = -1;
        // same call as the arrow buttons, with the 1-based position
        if (moved)
            root.ipc(["move", slug, String(to + 1)], () => root.later());
    }

    readonly property var _settings: SettingsData.pluginSettings
    function cfg(key, fallback) {
        root._settings;
        return SettingsData.getPluginSetting("dmsProfiles", key, fallback);
    }

    function ipc(args, callback) {
        Proc.runCommand("dmsProfiles.settings." + args[0], ["dms", "ipc", "call", "profiles"].concat(args), (out, code) => {
            if (callback)
                callback(String(out).trim(), code);
        }, 0, 15000);
    }

    // The daemon may still be starting when the page opens, and then the call
    // comes back empty. Without a second attempt the page stays empty for as
    // long as it is open, which reads like "there are no profiles".
    property int tries: 0

    function refresh() {
        root.ipc(["list"], (out, code) => {
            let liste = null;
            if (code === 0) {
                try {
                    liste = JSON.parse(out);
                } catch (e) {}
            }
            if (liste === null) {
                if (root.tries < 6) {
                    root.tries++;
                    refreshTimer.restart();
                }
                return;
            }
            root.tries = 0;
            // a refresh during a drag would throw the rows back
            if (root.dragSlug === "")
                root.profiles = liste;
        });
    }

    // Store operations finish asynchronously in the daemon
    // An empty path takes the folder away again
    function setFolder(slug, path) {
        root.ipc(["folder", slug, path], () => root.later());
    }

    // One tooltip for all the folder lines. Moving from one hot area to the next
    // can deliver "entered" before "exited"; only the owner may hide it.
    property var hintOwner: null

    DankTooltipV2 {
        id: hint
    }

    function showHint(text, item) {
        root.hintOwner = item;
        hint.show(text, item, 0, 0, "top");
    }

    function hideHint(item) {
        if (root.hintOwner !== item)
            return;
        root.hintOwner = null;
        hint.hide();
    }

    // Same folder browser as the DMS wallpaper settings
    FileBrowserModal {
        id: folderBrowser
        browserTitle: I18n.tr("Choose wallpaper folder", "wallpaper folder file browser title")
        browserIcon: "folder"
        browserType: "wallpaper"
        folderMode: true
        showHiddenFiles: true
        onFileSelected: path => {
            root.setFolder(root.folderTarget, path);
            close();
        }
    }

    function later() {
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 700
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    // ------------------------------------------------------------------ profiles
    StyledText {
        width: parent ? parent.width : implicitWidth
        text: I18n.trFor("dmsProfiles", "Profiles")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent ? parent.width : implicitWidth
        wrapMode: Text.WordWrap
        text: I18n.trFor("dmsProfiles", "A profile stores the look of the shell: theme and accent, light or dark, wallpaper, bars, frame, transparency, fonts and desktop widgets. Changes you make later are saved into the active profile.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    Row {
        width: parent ? parent.width : implicitWidth
        spacing: Theme.spacingS

        DankTextField {
            id: newName
            width: parent.width - createButton.width - Theme.spacingS
            height: 40
            placeholderText: I18n.trFor("dmsProfiles", "Name for a new profile from the current look")
            onAccepted: createButton.clicked()
        }

        DankButton {
            id: createButton
            text: I18n.trFor("dmsProfiles", "Create")
            buttonHeight: 40
            enabled: newName.text.trim().length > 0
            opacity: enabled ? 1 : 0.5
            onClicked: {
                root.ipc(["create", newName.text.trim()]);
                newName.text = "";
                root.later();
            }
        }
    }

    StyledText {
        visible: root.profiles.length === 0
        text: I18n.trFor("dmsProfiles", "No profiles yet.")
        color: Theme.surfaceVariantText
        font.pixelSize: Theme.fontSizeMedium
    }

    StyledText {
        visible: root.profiles.length > 1
        width: parent ? parent.width : implicitWidth
        wrapMode: Text.WordWrap
        text: I18n.trFor("dmsProfiles", "Drag a row to change the order.")
        color: Theme.surfaceVariantText
        font.pixelSize: Theme.fontSizeSmall
    }

    Item {
        id: list
        width: parent ? parent.width : implicitWidth
        height: Math.max(0, root.profiles.length * (root.rowHeight + root.rowGap) - root.rowGap)

        Repeater {
            model: root.profiles

            Rectangle {
                id: row
                required property var modelData
                required property int index

                readonly property bool renaming: root.renameSlug === modelData.slug
                readonly property bool deleting: root.deleteSlug === modelData.slug
                readonly property bool dragged: root.dragSlug === modelData.slug
                readonly property int place: root.displayOrder.indexOf(modelData.slug)

                width: list.width
                height: root.rowHeight
                y: dragged ? root.dragY : place * (root.rowHeight + root.rowGap)
                z: dragged ? 10 : 0
                scale: dragged ? 1.02 : 1
                radius: Theme.cornerRadius
                color: dragged ? Theme.surfaceContainerHighest : (modelData.active ? Theme.withAlpha(Theme.primary, 0.12) : Theme.withAlpha(Theme.surfaceContainerHigh, 0.6))
                border.width: modelData.active || dragged ? 1 : 0
                border.color: Theme.primary

                Behavior on y {
                    enabled: !row.dragged
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                    }
                }

                // Grab anywhere on the row except the buttons
                MouseArea {
                    id: grip
                    anchors.fill: parent
                    anchors.rightMargin: buttons.width + Theme.spacingS
                    enabled: !row.renaming && root.profiles.length > 1
                    hoverEnabled: true
                    cursorShape: row.dragged ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    preventStealing: true

                    property real offset: 0

                    onPressed: mouse => {
                        offset = mouse.y;
                        root.beginDrag(row.modelData.slug, row.index, row.y);
                    }
                    onPositionChanged: mouse => {
                        if (!row.dragged)
                            return;
                        const p = mapToItem(list, mouse.x, mouse.y);
                        root.moveDrag(p.y - offset);
                    }
                    onReleased: root.endDrag()
                    onCanceled: root.endDrag()
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingS

                    DankIcon {
                        id: handle
                        anchors.verticalCenter: parent.verticalCenter
                        name: "drag_indicator"
                        size: Theme.iconSize
                        color: Theme.surfaceVariantText
                        opacity: root.profiles.length > 1 ? 1 : 0.3
                    }

                    Image {
                        width: 80
                        height: 48
                        anchors.verticalCenter: parent.verticalCenter
                        source: row.modelData.thumb ? "file://" + row.modelData.thumb : ""
                        sourceSize.width: 160
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Item {
                        width: parent.width - handle.width - 80 - buttons.width - Theme.spacingS * 3
                        height: parent.height

                        DankTextField {
                            id: renameField
                            visible: row.renaming
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 36
                            text: row.modelData.name
                            onAccepted: {
                                root.ipc(["rename", row.modelData.slug, text.trim()]);
                                root.renameSlug = "";
                                root.later();
                            }
                        }

                        Column {
                            visible: !row.renaming
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width

                            StyledText {
                                width: parent.width
                                elide: Text.ElideRight
                                text: row.modelData.name
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: row.modelData.active ? Font.Medium : Font.Normal
                            }

                            StyledText {
                                visible: row.modelData.active
                                width: parent.width
                                elide: Text.ElideRight
                                text: I18n.trFor("dmsProfiles", "active")
                                color: Theme.primary
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            // Wallpaper folder of the profile: click to choose, the cross removes it
                            Row {
                                width: parent.width
                                spacing: 4

                                DankIcon {
                                    id: folderIcon
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "folder"
                                    size: 14
                                    color: row.modelData.wallpaperFolder ? Theme.primary : Theme.surfaceVariantText
                                }

                                StyledText {
                                    id: folderName
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.min(implicitWidth, parent.width - folderIcon.width - (clearIcon.visible ? clearIcon.width + parent.spacing : 0) - parent.spacing)
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    wrapMode: Text.NoWrap
                                    text: row.modelData.wallpaperFolder ? row.modelData.wallpaperFolder.replace(/\/+$/, "").split("/").pop() : I18n.trFor("dmsProfiles", "Choose folder")
                                    color: row.modelData.wallpaperFolder ? Theme.primary : Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.showHint(row.modelData.wallpaperFolder ? I18n.trFor("dmsProfiles", "Change folder: %1").arg(row.modelData.wallpaperFolder) : I18n.trFor("dmsProfiles", "Choose a wallpaper folder for this profile"), parent)
                                        onExited: root.hideHint(parent)
                                        onClicked: {
                                            root.hideHint(parent);
                                            root.folderTarget = row.modelData.slug;
                                            folderBrowser.open();
                                        }
                                    }
                                }

                                DankIcon {
                                    id: clearIcon
                                    visible: !!row.modelData.wallpaperFolder
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "close"
                                    size: 14
                                    color: Theme.surfaceVariantText

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.showHint(I18n.trFor("dmsProfiles", "Remove the wallpaper folder"), parent)
                                        onExited: root.hideHint(parent)
                                        onClicked: {
                                            root.hideHint(parent);
                                            root.setFolder(row.modelData.slug, "");
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        id: buttons
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        DankActionButton {
                            visible: !row.modelData.active
                            iconName: "play_arrow"
                            tooltipText: I18n.trFor("dmsProfiles", "Apply")
                            onClicked: root.ipc(["apply", row.modelData.slug], () => root.later())
                        }
                        DankActionButton {
                            visible: row.modelData.active && row.modelData.resettable
                            iconName: "undo"
                            tooltipText: I18n.trFor("dmsProfiles", "Undo changes since the profile was activated")
                            onClicked: root.ipc(["reset", row.modelData.slug], () => root.later())
                        }
                        DankActionButton {
                            iconName: row.modelData.shown === false ? "visibility_off" : "visibility"
                            tooltipText: row.modelData.shown === false ? I18n.trFor("dmsProfiles", "Hidden from the profile picker") : I18n.trFor("dmsProfiles", "Shown in the profile picker")
                            opacity: row.modelData.shown === false ? 0.5 : 1
                            onClicked: root.ipc(["show", row.modelData.slug, row.modelData.shown === false ? "true" : "false"], () => root.later())
                        }
                        DankActionButton {
                            iconName: "arrow_upward"
                            enabled: row.index > 0
                            opacity: enabled ? 1 : 0.3
                            onClicked: root.ipc(["move", row.modelData.slug, "left"], () => root.later())
                        }
                        DankActionButton {
                            iconName: "arrow_downward"
                            enabled: row.index < root.profiles.length - 1
                            opacity: enabled ? 1 : 0.3
                            onClicked: root.ipc(["move", row.modelData.slug, "right"], () => root.later())
                        }
                        DankActionButton {
                            iconName: row.renaming ? "check" : "edit"
                            tooltipText: I18n.trFor("dmsProfiles", "Rename")
                            onClicked: {
                                if (row.renaming) {
                                    root.ipc(["rename", row.modelData.slug, renameField.text.trim()]);
                                    root.renameSlug = "";
                                    root.later();
                                } else {
                                    root.renameSlug = row.modelData.slug;
                                }
                            }
                        }
                        DankActionButton {
                            iconName: row.deleting ? "delete_forever" : "delete"
                            iconColor: row.deleting ? Theme.error : Theme.surfaceText
                            tooltipText: row.deleting ? I18n.trFor("dmsProfiles", "Click again to delete") : I18n.trFor("dmsProfiles", "Delete")
                            onClicked: {
                                if (row.deleting) {
                                    root.ipc(["remove", row.modelData.slug]);
                                    root.deleteSlug = "";
                                    root.later();
                                } else {
                                    root.deleteSlug = row.modelData.slug;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ picker
    StyledText {
        width: parent ? parent.width : implicitWidth
        topPadding: Theme.spacingL
        text: I18n.trFor("dmsProfiles", "Profile picker")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent ? parent.width : implicitWidth
        wrapMode: Text.WordWrap
        text: I18n.trFor("dmsProfiles", "Open it with a keybind: dms ipc call profiles toggle")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    SelectionSetting {
        settingKey: "pickerView"
        label: I18n.trFor("dmsProfiles", "View")
        defaultValue: "strip"
        options: [
            {
                label: I18n.trFor("dmsProfiles", "Strip"),
                value: "strip"
            },
            {
                label: I18n.trFor("dmsProfiles", "Free, without a panel"),
                value: "free"
            },
            {
                label: I18n.trFor("dmsProfiles", "Carousel"),
                value: "carousel"
            },
            {
                label: I18n.trFor("dmsProfiles", "Grid"),
                value: "grid"
            }
        ]
    }

    SelectionSetting {
        settingKey: "pickerShape"
        label: I18n.trFor("dmsProfiles", "Shape")
        defaultValue: "portrait"
        options: [
            {
                label: I18n.trFor("dmsProfiles", "Portrait"),
                value: "portrait"
            },
            {
                label: I18n.trFor("dmsProfiles", "Landscape"),
                value: "landscape"
            },
            {
                label: I18n.trFor("dmsProfiles", "Square"),
                value: "square"
            },
            {
                label: I18n.trFor("dmsProfiles", "Circle"),
                value: "circle"
            },
            {
                label: I18n.trFor("dmsProfiles", "Hexagon"),
                value: "hexagon"
            },
            {
                label: I18n.trFor("dmsProfiles", "Diamond"),
                value: "diamond"
            }
        ]
    }

    ToggleSetting {
        settingKey: "pickerGlow"
        label: I18n.trFor("dmsProfiles", "Glow around the selection")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "pickerRing"
        label: I18n.trFor("dmsProfiles", "Outline around the selection")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "pickerCheck"
        label: I18n.trFor("dmsProfiles", "Check mark on the active profile")
        defaultValue: true
    }

    ToggleSetting {
        id: cornerTheme
        settingKey: "pickerCornerTheme"
        label: I18n.trFor("dmsProfiles", "Corner radius like windows")
        description: I18n.trFor("dmsProfiles", "Uses the window corner radius that DMS sets for the compositor.")
        defaultValue: true
    }

    SliderSetting {
        visible: !cornerTheme.value
        settingKey: "pickerCorner"
        label: I18n.trFor("dmsProfiles", "Corner radius")
        defaultValue: 12
        minimum: 0
        maximum: 60
        unit: "px"
    }

    // ------------------------------------------------------------------ transition
    StyledText {
        width: parent ? parent.width : implicitWidth
        topPadding: Theme.spacingL
        text: I18n.trFor("dmsProfiles", "Transition")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent ? parent.width : implicitWidth
        wrapMode: Text.WordWrap
        text: I18n.trFor("dmsProfiles", "While switching, the screen stands still for a moment and the animation runs onto the wallpaper of the new profile. Bars, windows and widgets then fade in with the new look.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    readonly property var transitionTypes: ["random", "fade", "wipe", "disc", "iris", "pixel", "stripes", "ember", "zoom", "slide", "doors", "blinds", "squares", "wave", "clock", "dots", "swirl", "ripple", "melt", "blur", "dissolve", "black", "shatter", "glitch", "glitchcode", "glitchvhs", "glitchsort", "glitchscan", "snow", "crt", "none"]

    // Names are listed here as literals so the translation tooling finds them
    function typeName(id) {
        switch (id) {
        case "random":
            return I18n.trFor("dmsProfiles", "Random");
        case "fade":
            return I18n.trFor("dmsProfiles", "Fade");
        case "wipe":
            return I18n.trFor("dmsProfiles", "Wipe");
        case "disc":
            return I18n.trFor("dmsProfiles", "Circle from the center");
        case "iris":
            return I18n.trFor("dmsProfiles", "Iris");
        case "pixel":
            return I18n.trFor("dmsProfiles", "Pixelate");
        case "stripes":
            return I18n.trFor("dmsProfiles", "Stripes");
        case "ember":
            return I18n.trFor("dmsProfiles", "Burn away");
        case "zoom":
            return I18n.trFor("dmsProfiles", "Zoom");
        case "slide":
            return I18n.trFor("dmsProfiles", "Slide away");
        case "doors":
            return I18n.trFor("dmsProfiles", "Doors");
        case "blinds":
            return I18n.trFor("dmsProfiles", "Blinds");
        case "squares":
            return I18n.trFor("dmsProfiles", "Tiles");
        case "wave":
            return I18n.trFor("dmsProfiles", "Wave");
        case "clock":
            return I18n.trFor("dmsProfiles", "Clock");
        case "dots":
            return I18n.trFor("dmsProfiles", "Dots");
        case "swirl":
            return I18n.trFor("dmsProfiles", "Swirl");
        case "ripple":
            return I18n.trFor("dmsProfiles", "Ripple");
        case "melt":
            return I18n.trFor("dmsProfiles", "Melt");
        case "blur":
            return I18n.trFor("dmsProfiles", "Blur");
        case "dissolve":
            return I18n.trFor("dmsProfiles", "Dissolve");
        case "black":
            return I18n.trFor("dmsProfiles", "Through black");
        case "shatter":
            return I18n.trFor("dmsProfiles", "Shatter");
        case "glitch":
            return I18n.trFor("dmsProfiles", "Hack: data corruption");
        case "glitchcode":
            return I18n.trFor("dmsProfiles", "Hack: code rain");
        case "glitchvhs":
            return I18n.trFor("dmsProfiles", "Hack: signal loss");
        case "glitchsort":
            return I18n.trFor("dmsProfiles", "Hack: pixel sorting");
        case "glitchscan":
            return I18n.trFor("dmsProfiles", "Hack: scan");
        case "snow":
            return I18n.trFor("dmsProfiles", "Snowstorm");
        case "crt":
            return I18n.trFor("dmsProfiles", "CRT off");
        case "none":
            return I18n.trFor("dmsProfiles", "Off");
        }
        return id;
    }

    SelectionSetting {
        id: transitionType
        settingKey: "transition"
        label: I18n.trFor("dmsProfiles", "Type")
        defaultValue: "random"
        options: root.transitionTypes.map(t => ({
                    "label": root.typeName(t),
                    "value": t
                }))
    }

    Column {
        width: parent ? parent.width : implicitWidth
        spacing: Theme.spacingS
        visible: transitionType.value === "random"

        readonly property var pool: {
            const l = root.cfg("transitionPool", []);
            return Array.isArray(l) ? l : [];
        }
        readonly property var singleTypes: root.transitionTypes.filter(t => t !== "random" && t !== "none")

        function toggle(id) {
            let l = pool.length > 0 ? pool.slice() : singleTypes.slice();
            const i = l.indexOf(id);
            if (i >= 0)
                l.splice(i, 1);
            else
                l.push(id);
            SettingsData.setPluginSetting("dmsProfiles", "transitionPool", l.length === singleTypes.length ? [] : l);
        }

        id: poolBox

        StyledText {
            text: I18n.trFor("dmsProfiles", "Random picks from")
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
        }

        Flow {
            width: parent.width
            spacing: Theme.spacingXS

            Repeater {
                model: poolBox.singleTypes

                Rectangle {
                    id: chip
                    required property string modelData
                    readonly property bool included: poolBox.pool.length === 0 || poolBox.pool.indexOf(modelData) >= 0
                    width: chipText.implicitWidth + Theme.spacingM * 2
                    height: 30
                    radius: 15
                    color: included ? Theme.withAlpha(Theme.primary, chipMouse.containsMouse ? 0.35 : 0.22) : (chipMouse.containsMouse ? Theme.withAlpha(Theme.outline, 0.15) : "transparent")
                    border.width: 1
                    border.color: included ? Theme.primary : Theme.withAlpha(Theme.outline, 0.4)

                    StyledText {
                        id: chipText
                        anchors.centerIn: parent
                        text: root.typeName(chip.modelData)
                        color: chip.included ? Theme.primary : Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: poolBox.toggle(chip.modelData)
                    }
                }
            }
        }
    }

    SliderSetting {
        settingKey: "transitionMs"
        label: I18n.trFor("dmsProfiles", "Duration")
        defaultValue: 1200
        minimum: 300
        maximum: 4000
        unit: "ms"
    }

    ToggleSetting {
        settingKey: "transitionGlow"
        label: I18n.trFor("dmsProfiles", "Glowing edge")
        description: I18n.trFor("dmsProfiles", "The edge of the animation glows in the accent color of the new profile.")
        defaultValue: true
    }

    DankButton {
        text: I18n.trFor("dmsProfiles", "Preview transition")
        buttonHeight: 36
        onClicked: root.ipc(["previewTransition", ""])
    }

    // ------------------------------------------------------------------ advanced
    StyledText {
        width: parent ? parent.width : implicitWidth
        topPadding: Theme.spacingL
        text: I18n.trFor("dmsProfiles", "Advanced")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "autosave"
        label: I18n.trFor("dmsProfiles", "Save changes into the active profile")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "useOriginalWallpaper"
        label: I18n.trFor("dmsProfiles", "Use the original wallpaper file")
        description: I18n.trFor("dmsProfiles", "Show the picture from where it lives, as long as it exists, so wallpaper cycling and carousels see its folder. The copy in the profile is used when the file is gone.")
        defaultValue: true
    }

    StringSetting {
        settingKey: "profilePlugins"
        label: I18n.trFor("dmsProfiles", "Plugins saved with a profile")
        description: I18n.trFor("dmsProfiles", "Plugin ids separated by commas, for example audioFx.")
        placeholder: "audioFx"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "saveCommand"
        label: I18n.trFor("dmsProfiles", "Save command")
        description: I18n.trFor("dmsProfiles", "Optional. Runs when a profile is saved and prints JSON, stored with the profile. For settings outside DMS.")
        defaultValue: ""
    }

    StringSetting {
        settingKey: "applyCommand"
        label: I18n.trFor("dmsProfiles", "Apply command")
        description: I18n.trFor("dmsProfiles", "Optional. Runs while switching, before the new desktop is shown. DMS_PROFILE_DIR, DMS_PROFILE_SLUG and DMS_PROFILE_NAME are set.")
        defaultValue: ""
    }
}

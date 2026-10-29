// Profiles: one card in the profile picker.
//
// Preview image inside a shape (shaders/card.frag), optionally the name below.
// The image is `thumb` (wide preview made from the wallpaper), else the
// wallpaper itself.
//
// Shapes: portrait (9:16), landscape (16:10), square, circle, hexagon, diamond,
// skewed (portrait with a slanted frame; the picture stays upright)

pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: card

    property var profile: null
    property string shape: "portrait"
    property real imageHeight: 290
    property bool selected: false
    property real dim: 0
    property bool showName: true

    signal hovered
    signal activated

    // skewed: the box also holds the slant (0.35 * height), so the frame itself is 0.9 - 0.35 = 9:16
    readonly property real aspectRatio: shape === "portrait" ? 9 / 16 : (shape === "landscape" ? 16 / 10 : (shape === "skewed" ? 0.9 : 1))
    // frame shear: x moves by skew * y, so the top leans right
    readonly property real skew: shape === "skewed" ? -0.35 : 0
    readonly property real imageWidth: imageHeight * aspectRatio
    readonly property int shapeIndex: ({
            "circle": 1,
            "hexagon": 2,
            "diamond": 3
        })[shape] ?? 0
    readonly property real padding: Math.max(16, imageHeight * 0.12)
    readonly property bool glowEnabled: {
        SettingsData.pluginSettings;
        return SettingsData.getPluginSetting("dmsProfiles", "pickerGlow", true);
    }
    readonly property bool ringEnabled: {
        SettingsData.pluginSettings;
        return SettingsData.getPluginSetting("dmsProfiles", "pickerRing", true);
    }
    readonly property bool checkEnabled: {
        SettingsData.pluginSettings;
        return SettingsData.getPluginSetting("dmsProfiles", "pickerCheck", true);
    }
    readonly property bool ringEmphasized: ringEnabled && highlight > 0.01
    // Corner radius in real pixels, like the windows: by default the niri window
    // radius as DMS sets it (niriLayoutRadiusOverride, else the theme radius),
    // otherwise a fixed value. It must not scale with the card, or large
    // carousel cards stop matching the windows.
    readonly property real corner: {
        SettingsData.pluginSettings;
        if (SettingsData.getPluginSetting("dmsProfiles", "pickerCornerTheme", true))
            return SettingsData.niriLayoutRadiusOverride >= 0 ? SettingsData.niriLayoutRadiusOverride : Theme.cornerRadius;
        return SettingsData.getPluginSetting("dmsProfiles", "pickerCorner", 12);
    }

    width: imageWidth
    height: imageHeight + (showName ? Theme.spacingS + nameLabel.implicitHeight : 0)

    property real highlight: selected ? 1 : 0
    Behavior on highlight {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Image {
        id: imageSource
        visible: false
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        source: card.profile ? "file://" + (card.profile.thumb || card.profile.wallpaper || "") : ""
        sourceSize.width: 1600
    }

    Rectangle {
        // placeholder until the image is loaded
        width: card.imageWidth
        height: card.imageHeight
        radius: card.shapeIndex === 1 ? width / 2 : Math.min(card.corner, width / 2)
        color: Theme.surfaceContainerHigh
        visible: imageSource.status !== Image.Ready
    }

    ShaderEffect {
        x: -card.padding
        y: -card.padding
        width: card.imageWidth + 2 * card.padding
        height: card.imageHeight + 2 * card.padding
        visible: imageSource.status === Image.Ready
        blending: true

        property var source: imageSource
        property real shape: card.shapeIndex
        property real areaW: width
        property real areaH: height
        property real padding: card.padding
        property real imageW: imageSource.implicitWidth
        property real imageH: imageSource.implicitHeight
        // hexagon and diamond: rounding must not dissolve the shape
        property real corner: card.shapeIndex === 0 ? card.corner : Math.min(card.corner, card.imageHeight * 0.2)
        property real border: card.ringEmphasized ? 3 * Math.max(1, card.imageHeight / 400) : 1
        property real glow: card.glowEnabled ? card.highlight : 0
        property real dim: card.dim
        property real skew: card.skew
        // Color is shared by border and glow. Without the emphasized ring the
        // border stays subtle while the glow keeps the accent color.
        property color borderColor: card.ringEmphasized || (card.glowEnabled && card.highlight > 0.01 && !card.ringEnabled) ? Theme.primary : Theme.withAlpha(Theme.outline, 0.35)

        fragmentShader: Qt.resolvedUrl("shaders/card.frag.qsb")
    }

    // check mark for the active profile: top center on round shapes, else top right
    Rectangle {
        visible: card.checkEnabled && (card.profile?.active ?? false)
        width: Theme.iconSize + 6
        height: width
        radius: width / 2
        color: Theme.surfaceContainer
        // the right edge of a sheared frame moves with the row (skew 0: nothing changes)
        x: card.shapeIndex === 0 ? card.imageWidth - width - Theme.spacingS + card.skew * (y + height / 2) : (card.imageWidth - width) / 2
        y: card.shapeIndex === 0 ? Theme.spacingS : card.imageHeight * (card.shapeIndex === 1 ? 0.04 : 0.1)

        DankIcon {
            anchors.centerIn: parent
            name: "check_circle"
            size: Theme.iconSize
            color: Theme.primary
        }
    }

    StyledText {
        id: nameLabel
        visible: card.showName
        y: card.imageHeight + Theme.spacingS
        width: Math.max(card.imageWidth, 120)
        // centered under the bottom edge of the frame (skewed: that edge is shifted)
        x: (card.imageWidth - width) / 2 + card.skew * card.imageHeight / 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: card.profile?.name ?? ""
        color: card.selected ? Theme.primary : Theme.surfaceText
        font.pixelSize: Theme.fontSizeMedium
        font.weight: card.selected ? Font.Medium : Font.Normal
    }

    QtObject {
        id: shearMask
        function contains(pt: point): bool {
            const dx = pt.x - card.imageWidth / 2 - card.skew * (pt.y - card.imageHeight / 2);
            return Math.abs(dx) <= (card.imageWidth - Math.abs(card.skew) * card.imageHeight) / 2;
        }
    }

    MouseArea {
        width: card.imageWidth
        height: card.imageHeight
        // only the sheared frame counts, not the corners of its bounding box
        containmentMask: card.skew === 0 ? null : shearMask
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: card.hovered()
        onClicked: card.activated()
    }
}

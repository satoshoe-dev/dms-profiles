// Profiles: profile picker as a carousel.
//
// The selected profile stands large in the center, the others get smaller,
// darker and fainter with every step. Mouse wheel, arrow keys (also h/l,
// Page Up/Down), Home/End or a click on a side card rotate; a click on the
// center card or Enter applies. A click elsewhere closes.
//
// Layout: offset and size follow a geometric series (factor `falloff` per
// step), so cards move closer together towards the outside. `pos` follows the
// selection with an animation, which makes the carousel rotate smoothly.

pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: carousel

    property var ctl: null
    property string shape: "portrait"

    readonly property int count: ctl ? ctl.profiles.length : 0
    readonly property real falloff: 0.74

    property real pos: ctl ? ctl.selected : 0
    Behavior on pos {
        NumberAnimation {
            duration: 340
            easing.type: Easing.OutCubic
        }
    }

    readonly property real aspectRatio: shape === "portrait" ? 9 / 16 : (shape === "landscape" ? 16 / 10 : 1)
    // share of the height for the center card; larger in the dashboard tab,
    // where the labels are smaller
    property real heightShare: 0.54
    property real labelSize: Theme.fontSizeXLarge * 1.3
    // labels: white on the dimmed screen, theme colors in the dashboard
    property color textColor: "white"
    property color textColorDim: Qt.rgba(1, 1, 1, 0.7)
    readonly property real centerHeight: {
        if (shape === "portrait")
            return height * heightShare;
        if (shape === "landscape")
            return Math.min(height * heightShare * 0.82, width * 0.38 / aspectRatio);
        return height * heightShare * 0.82;
    }
    readonly property real centerWidth: centerHeight * aspectRatio

    function offset(d) {
        const a = Math.abs(d);
        return Math.sign(d) * centerWidth * 0.8 * (1 - Math.pow(falloff, a)) / (1 - falloff);
    }

    function step(n) {
        if (!ctl || count === 0)
            return;
        ctl.selected = Math.max(0, Math.min(count - 1, ctl.selected + n));
    }

    // background: wheel rotates, click closes
    MouseArea {
        anchors.fill: parent
        property real accumulated: 0
        onClicked: carousel.ctl.hidePicker()
        onWheel: wheel => {
            const d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            accumulated += d;
            while (accumulated >= 120) {
                carousel.step(-1);
                accumulated -= 120;
            }
            while (accumulated <= -120) {
                carousel.step(1);
                accumulated += 120;
            }
        }
    }

    StyledText {
        anchors.centerIn: parent
        visible: carousel.count === 0
        text: (carousel.ctl ? carousel.ctl.emptyLabel : "")
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeLarge
    }

    Repeater {
        model: carousel.ctl ? carousel.ctl.profiles : []

        ProfileCard {
            id: card
            required property var modelData
            required property int index

            readonly property real d: index - carousel.pos
            readonly property real distance: Math.abs(d)

            profile: modelData
            shape: carousel.shape
            imageHeight: carousel.centerHeight
            showName: false
            selected: distance < 0.5
            dim: Math.min(0.6, distance * 0.28)

            x: carousel.width / 2 + carousel.offset(d) - imageWidth / 2
            y: (carousel.height - imageHeight) / 2 - carousel.height * 0.04
            scale: Math.pow(carousel.falloff, distance)
            transformOrigin: Item.Center
            z: 1000 - distance * 10
            opacity: Math.max(0, 1 - Math.max(0, distance - 1) * 0.22)
            visible: opacity > 0.02

            onActivated: {
                if (index === carousel.ctl.selected)
                    carousel.ctl.choose(index);
                else
                    carousel.ctl.selected = index;
            }
        }
    }

    // labels below the center card
    Column {
        visible: carousel.count > 0
        z: 2000
        anchors.horizontalCenter: parent.horizontalCenter
        y: (carousel.height + carousel.centerHeight) / 2 - carousel.height * 0.04 + Theme.spacingXL
        spacing: Theme.spacingXS

        readonly property var current: carousel.ctl && carousel.count > 0 ? carousel.ctl.profiles[Math.max(0, Math.min(carousel.count - 1, carousel.ctl.selected))] : null

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: parent.current ? parent.current.name : ""
            color: carousel.textColor
            font.pixelSize: carousel.labelSize
            font.weight: Font.Medium
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: parent.current ? ((parent.current.active ? carousel.ctl.activeLabel : I18n.trFor("dmsProfiles", "Enter or click to apply")) + "  ·  " + (carousel.ctl.selected + 1) + " / " + carousel.count) : ""
            color: carousel.textColorDim
            font.pixelSize: Theme.fontSizeMedium
        }
    }
}

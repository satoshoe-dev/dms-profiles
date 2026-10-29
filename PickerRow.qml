// Profiles: profile picker as a row (views "strip" and "free").
//
// Strip (framed): all cards side by side on a framed surface. Free: the same row
// without a surface, cards stand directly on the dimmed screen. If the cards
// do not fit the width, the row is scaled down instead of cut off.

pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: row

    property var ctl: null
    property bool framed: true
    property string shape: "portrait"

    readonly property int count: ctl ? ctl.profiles.length : 0
    readonly property real baseHeight: shape === "portrait" || shape === "skewed" ? 290 : (shape === "landscape" ? 170 : 200)
    readonly property real baseWidth: baseHeight * (shape === "portrait" ? 9 / 16 : (shape === "landscape" ? 16 / 10 : (shape === "skewed" ? 0.9 : 1)))
    // skewed frames nest into each other: their boxes overlap by the slant
    readonly property real overlap: shape === "skewed" ? 0.35 * baseHeight : 0
    readonly property real gap: framed ? Theme.spacingM : Theme.spacingL
    readonly property real naturalWidth: count * baseWidth + Math.max(0, count - 1) * (gap - overlap)
    // fit width and height (the dashboard tab is only about 340 px high)
    readonly property real factor: count > 0 ? Math.max(0.2, Math.min(1, (width - Theme.spacingL * 8) / naturalWidth, (height - Theme.spacingL * 3 - Theme.fontSizeMedium * 2) / baseHeight)) : 1

    Rectangle {
        visible: row.framed
        anchors.centerIn: cards
        width: cards.width + Theme.spacingL * 2
        height: cards.height + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainer, 0.85)
        border.width: 1
        border.color: Theme.withAlpha(Theme.outline, 0.25)

        // clicks on the surface do not close the picker
        MouseArea {
            anchors.fill: parent
        }
    }

    StyledText {
        anchors.centerIn: parent
        visible: row.count === 0
        text: I18n.trFor("dmsProfiles", "No profiles yet. Create one in Settings under Profiles.")
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeMedium
    }

    Row {
        id: cards
        anchors.centerIn: parent
        spacing: (row.gap - row.overlap) * row.factor

        Repeater {
            model: row.ctl ? row.ctl.profiles : []

            ProfileCard {
                required property var modelData
                required property int index

                profile: modelData
                shape: row.shape
                imageHeight: row.baseHeight * row.factor
                // narrow cards (dashboard) without names, they would overlap
                showName: imageWidth >= 110
                selected: index === row.ctl.selected
                scale: selected ? 1.05 : 1.0
                z: selected ? 1 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }

                onHovered: row.ctl.selected = index
                onActivated: row.ctl.choose(index)
            }
        }
    }
}

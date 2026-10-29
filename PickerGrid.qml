// Profiles: profile picker as a grid across the whole screen.
//
// All profiles are spread over the area as large as possible; column counts
// are tried until the cards are largest.
//   portrait, landscape, square, circle: plain grid, names below the cards.
//   hexagon: honeycomb with pointy tops (as shaders/card.frag draws it), every
//            second row shifted by half a cell.
//   diamond: shifted rows, edges run parallel.
// Gap between edges = niri window gap (as DMS sets it: niriLayoutGapsOverride,
// else the bar spacing, at least 4 px).
//
// Hovering selects, click applies; arrow up/down jump one row (the column
// count is published in ctl.gridColumns).

pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: grid

    property var ctl: null
    property string shape: "portrait"

    readonly property int count: ctl ? ctl.profiles.length : 0
    readonly property real gap: {
        const o = SettingsData.niriLayoutGapsOverride;
        return o >= 0 ? o : Math.max(4, SettingsData.getPrimaryBarConfig()?.spacing ?? 4);
    }
    readonly property bool honeycomb: shape === "hexagon" || shape === "diamond"
    readonly property real aspectRatio: shape === "portrait" ? 9 / 16 : (shape === "landscape" ? 16 / 10 : 1)
    // can be reduced from outside (dashboard tab)
    property real margin: Math.max(48, width * 0.04)
    property real labelSpace: honeycomb ? 96 : 0
    readonly property real areaW: width - 2 * margin
    readonly property real areaH: height - 2 * margin - labelSpace
    readonly property real nameHeight: honeycomb ? 0 : Theme.spacingS + Theme.fontSizeMedium * 1.5

    // layout result: columns and card size (imageHeight)
    readonly property var layout: {
        const n = Math.max(1, count);
        const g = gap;
        let best = {
            "columns": 1,
            "height": 10
        };
        for (let columns = 1; columns <= n; columns++) {
            const rows = Math.ceil(n / columns);
            let h;
            if (shape === "hexagon") {
                // R = circumradius, card = 2R x 2R, cell sqrt(3)R wide and 2R high
                const o = rows > 1 ? 0.5 : 0;
                const rW = (areaW - g * (columns - 1 + o)) / (1.7320508 * (columns + o));
                const rH = (areaH - 0.866 * g * (rows - 1)) / (1.5 * (rows - 1) + 2);
                h = 2 * Math.min(rW, rH);
            } else if (shape === "diamond") {
                // h = half diagonal, a = h + g/sqrt2 = step
                const c = g / 1.4142136;
                const o = rows > 1 ? 1 : 0;
                const hW = (areaW - c * (2 * (columns - 1) + o)) / (2 * (columns - 1) + 2 + o);
                const hH = (areaH - c * (rows - 1)) / (rows + 1);
                h = 2 * Math.min(hW, hH);
            } else {
                const w = (areaW - (columns - 1) * g) / columns;
                h = Math.min(w / aspectRatio, (areaH - (rows - 1) * g) / rows - nameHeight);
            }
            if (h > best.height + 0.5)
                best = {
                    "columns": columns,
                    "height": h
                };
        }
        best.height = Math.min(best.height, areaH * 0.7);
        return best;
    }
    readonly property int columns: layout.columns
    readonly property int rows: Math.ceil(Math.max(1, count) / columns)
    readonly property real cardSize: layout.height

    // total size for centering
    readonly property real blockW: {
        const g = gap;
        if (shape === "hexagon") {
            const R = cardSize / 2;
            const o = rows > 1 ? 0.5 : 0;
            return 1.7320508 * R * (columns + o) + g * (columns - 1 + o);
        }
        if (shape === "diamond") {
            const a = cardSize / 2 + g / 1.4142136;
            return (columns - 1) * 2 * a + cardSize + (rows > 1 ? a : 0);
        }
        return columns * cardSize * aspectRatio + (columns - 1) * g;
    }
    readonly property real blockH: {
        const g = gap;
        if (shape === "hexagon") {
            const R = cardSize / 2;
            return (rows - 1) * (1.5 * R + 0.866 * g) + 2 * R;
        }
        if (shape === "diamond") {
            const a = cardSize / 2 + g / 1.4142136;
            return (rows - 1) * a + cardSize;
        }
        return rows * (cardSize + nameHeight) + (rows - 1) * g;
    }
    readonly property real x0: (width - blockW) / 2
    readonly property real y0: margin + (areaH - blockH) / 2

    onColumnsChanged: if (ctl) ctl.gridColumns = columns
    Component.onCompleted: if (ctl) ctl.gridColumns = columns
    Component.onDestruction: if (ctl) ctl.gridColumns = 1

    StyledText {
        anchors.centerIn: parent
        visible: grid.count === 0
        text: (grid.ctl ? grid.ctl.emptyLabel : "")
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeLarge
    }

    Repeater {
        model: grid.ctl ? grid.ctl.profiles : []

        ProfileCard {
            id: tile
            required property var modelData
            required property int index

            readonly property int column: index % grid.columns
            readonly property int row: Math.floor(index / grid.columns)
            // cards of the last, incomplete row are centered in the plain grid
            readonly property int inRow: row === grid.rows - 1 ? grid.count - row * grid.columns : grid.columns

            profile: modelData
            shape: grid.shape
            imageHeight: grid.cardSize
            showName: !grid.honeycomb
            selected: index === grid.ctl.selected
            // honeycomb cells touch each other: no scaling, or they overlap
            scale: selected && !grid.honeycomb ? 1.04 : 1.0
            z: selected ? 10 : 0

            x: {
                const g = grid.gap;
                if (grid.shape === "hexagon") {
                    const R = grid.cardSize / 2;
                    const dx = 1.7320508 * R + g;
                    // the card is 2R wide, the cell only sqrt(3)R: shift left by the difference
                    return grid.x0 + column * dx + (row % 2) * dx / 2 - (2 - 1.7320508) * R / 2;
                }
                if (grid.shape === "diamond") {
                    const a = grid.cardSize / 2 + g / 1.4142136;
                    return grid.x0 + column * 2 * a + (row % 2) * a;
                }
                const b = grid.cardSize * grid.aspectRatio;
                const rowW = inRow * b + (inRow - 1) * g;
                return (grid.width - rowW) / 2 + column * (b + g);
            }
            y: {
                const g = grid.gap;
                if (grid.shape === "hexagon")
                    return grid.y0 + row * (1.5 * grid.cardSize / 2 + 0.866 * g);
                if (grid.shape === "diamond") {
                    const a = grid.cardSize / 2 + g / 1.4142136;
                    return grid.y0 + row * a;
                }
                return grid.y0 + row * (grid.cardSize + grid.nameHeight + g);
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.shortDuration
                    easing.type: Easing.OutCubic
                }
            }

            onHovered: grid.ctl.selected = index
            onActivated: grid.ctl.choose(index)
        }
    }

    // name of the selected profile (honeycomb cards show no names)
    Column {
        visible: grid.honeycomb && grid.count > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(0, grid.margin - Theme.spacingS)
        spacing: Theme.spacingXS
        z: 20

        readonly property var current: grid.ctl && grid.count > 0 ? grid.ctl.profiles[Math.max(0, Math.min(grid.count - 1, grid.ctl.selected))] : null

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: parent.current ? parent.current.name : ""
            color: "white"
            font.pixelSize: Theme.fontSizeXLarge * 1.2
            font.weight: Font.Medium
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: parent.current ? (parent.current.active ? grid.ctl.activeLabel : I18n.trFor("dmsProfiles", "Enter or click to apply")) : ""
            color: Qt.rgba(1, 1, 1, 0.7)
            font.pixelSize: Theme.fontSizeMedium
        }
    }
}

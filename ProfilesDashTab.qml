// Dashboard tab "Profiles" (DMS 2.0, surface "dash" in plugin.json; opened with
// `dms ipc call dash open plugin_dmsProfiles`). DMS 1.6 does not know the
// surface and never loads this file.
//
// Shows the profiles as in the picker (strip, carousel or grid, with the shape
// from the settings), applies one on click and saves the current look under a
// new name. Switching and saving run in the daemon, the same way as the picker.

pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Modules.DDash

DashTabComponent {
    id: root

    // taller than the other tabs: carousel and grid need the room
    implicitHeight: Math.max(DashMetrics.tabMinHeight, 540)
    clip: true
    focusTarget: nameField

    readonly property var daemon: pluginService && pluginService.pluginDaemonInstances ? (pluginService.pluginDaemonInstances[pluginId] || null) : null
    property string status: ""
    property bool busy: false
    property string pendingName: ""

    // Interface for the picker views, as the daemon offers it
    readonly property var profiles: root.daemon ? root.daemon.profiles : []
    property int selected: 0
    readonly property string activeLabel: I18n.trFor("dmsProfiles", "active profile")
    readonly property string emptyLabel: I18n.trFor("dmsProfiles", "No profiles yet. Create one in Settings under Profiles.")
    property int gridColumns: 1
    function choose(i) {
        if (i >= 0 && i < root.profiles.length)
            root.applyProfile(root.profiles[i].slug, root.profiles[i].name);
    }
    function hidePicker() {
    }
    readonly property var _settings: SettingsData.pluginSettings
    readonly property string pickerView: {
        root._settings;
        return SettingsData.getPluginSetting("dmsProfiles", "pickerView", "strip");
    }
    readonly property string pickerShape: {
        root._settings;
        return SettingsData.getPluginSetting("dmsProfiles", "pickerShape", "portrait");
    }

    function selectActive() {
        const active = root.profiles.findIndex(p => p.active);
        root.selected = active >= 0 ? active : 0;
    }

    onLiveChanged: {
        if (live)
            root.selectActive();
    }
    onProfilesChanged: {
        if (!root.busy)
            root.selectActive();
    }
    Component.onCompleted: root.selectActive()

    function errorText(message) {
        return I18n.trFor("dmsProfiles", "Error: %1").arg(I18n.trFor("dmsProfiles", message));
    }

    function applyProfile(slug, name) {
        if (root.busy || !root.daemon)
            return;
        const r = root.daemon.apply(slug);
        if (r !== "started") {
            root.status = root.errorText(r === "busy" ? "A switch is already running" : "Profile not found");
            return;
        }
        root.busy = true;
        root.pendingName = name;
        root.status = I18n.trFor("dmsProfiles", "Switching to “%1”…").arg(name);
        // A profile may put the bar on another edge; the open dash would then
        // move along with it. Close it like the picker does.
        if (root.popoutService)
            root.popoutService.closeDankDash();
    }

    function saveProfile(name) {
        const n = name.trim();
        if (!n || root.busy || !root.daemon)
            return;
        root.busy = true;
        root.status = I18n.trFor("dmsProfiles", "Creating “%1”…").arg(n);
        root.daemon.create(n, err => {
            root.busy = false;
            if (err === "exists")
                root.status = root.errorText("A profile with this name exists");
            else if (err)
                root.status = root.errorText("Enter a name");
            else {
                root.status = I18n.trFor("dmsProfiles", "“%1” created and active").arg(n);
                nameField.text = "";
            }
            root.selectActive();
        });
    }

    Connections {
        target: root.daemon
        enabled: root.daemon !== null

        function onSwitched(slug, ok) {
            if (!root.busy)
                return;
            root.busy = false;
            root.status = ok ? I18n.trFor("dmsProfiles", "“%1” is active").arg(root.pendingName) : root.errorText(root.daemon.lastError || "Could not switch profile");
            root.selectActive();
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingM

        Row {
            width: parent.width
            spacing: Theme.spacingS

            DankTextField {
                id: nameField
                width: parent.width - saveButton.width - Theme.spacingS
                height: 40
                placeholderText: I18n.trFor("dmsProfiles", "Name for a new profile from the current look")
                leftIconName: "palette"
                onAccepted: root.saveProfile(text)
            }

            DankButton {
                id: saveButton
                text: I18n.trFor("dmsProfiles", "Create")
                iconName: "add"
                buttonHeight: 40
                enabled: !root.busy && nameField.text.trim().length > 0
                opacity: enabled ? 1 : 0.5
                onClicked: root.saveProfile(nameField.text)
            }
        }

        StyledText {
            width: parent.width
            elide: Text.ElideRight
            text: root.status !== "" ? root.status : (root.daemon ? I18n.trFor("dmsProfiles", "Click to apply · Scroll to browse · Manage profiles in the plugin settings") : I18n.trFor("dmsProfiles", "The Profiles plugin is not running"))
            color: root.status.startsWith(I18n.trFor("dmsProfiles", "Error: %1").split("%1")[0]) ? Theme.error : Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
        }

        Item {
            width: parent.width
            height: parent.height - y

            Loader {
                anchors.fill: parent
                active: root.live && root.daemon !== null
                sourceComponent: root.pickerView === "carousel" ? carouselView : (root.pickerView === "grid" ? gridView : rowView)
            }

            Component {
                id: rowView
                PickerRow {
                    ctl: root
                    framed: false
                    shape: root.pickerShape
                }
            }

            Component {
                id: carouselView
                PickerCarousel {
                    ctl: root
                    shape: root.pickerShape
                    heightShare: 0.62
                    labelSize: Theme.fontSizeLarge
                    textColor: Theme.surfaceText
                    textColorDim: Theme.surfaceVariantText
                }
            }

            Component {
                id: gridView
                PickerGrid {
                    ctl: root
                    shape: root.pickerShape
                    margin: Theme.spacingS
                    labelSpace: (shape === "hexagon" || shape === "diamond") ? 44 : 0
                }
            }
        }
    }
}

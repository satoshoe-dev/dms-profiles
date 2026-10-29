// Profiles: complete looks of the shell (theme, accent, light/dark, wallpaper,
// bars, frame, transparency, fonts, desktop widgets, chosen plugin settings)
// saved under a name and switched with a picker or IPC.
//
// Switching writes all settings to settings.json in one go and lets DMS reload
// the file. Setting the values one by one through SettingsData.set writes the
// file once per key; DMS then reads intermediate states back and loses values.

pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "ProfileMigration.js" as Migration

PluginComponent {
    id: root

    property var popoutService: null

    readonly property var visualKeys: [
        "customThemeFile", "registryThemeVariants", "currentThemeCategory", "currentThemeName",
        "matugenScheme", "matugenSmartMode", "matugenSourceMode", "matugenContrast", "terminalsAlwaysDark",
        "popupTransparency", "dockTransparency", "floatingWindowSyncGlobal", "floatingWindowTransparency",
        "floatingWindowForegroundLayers", "floatingWindowForegroundTransparency",
        "widgetBackgroundColor", "widgetBackgroundCustomColor", "widgetBackgroundCustomStrength",
        "widgetColorMode", "controlCenterTileColorMode", "buttonColorMode",
        "cornerRadius", "niriLayoutGapsOverride", "niriLayoutRadiusOverride", "niriLayoutBorderSize",
        "animationSpeed", "customAnimationDuration", "syncComponentAnimationSpeeds",
        "popoutAnimationSpeed", "popoutCustomAnimationDuration", "modalAnimationSpeed",
        "modalCustomAnimationDuration", "reduceMotion", "springBounce", "enableRippleEffects",
        "animationVariant", "motionEffect",
        "m3ElevationEnabled", "m3ElevationIntensity", "m3ElevationOpacity", "m3ElevationColorMode",
        "m3ElevationLightDirection", "m3ElevationCustomColor", "modalElevationEnabled",
        "popoutElevationEnabled", "barElevationEnabled",
        "blurEnabled", "blurForegroundLayers", "foregroundLayerTransparency", "blurLayerOutlineOpacity",
        "blurBorderEnabled", "blurBorderColor", "blurBorderCustomColor", "blurBorderOpacity",
        "wallpaperFillMode", "blurredWallpaperLayer", "blurWallpaperOnOverview",
        "wallpaperBackgroundColorMode", "wallpaperBackgroundCustomColor",
        "systemTrayIconTintMode", "systemTrayIconTintSaturation", "systemTrayIconTintStrength",
        "workspaceColorMode", "workspaceFocusedCustomColor", "workspaceOccupiedColorMode",
        "workspaceOccupiedCustomColor", "workspaceUnfocusedColorMode", "workspaceUnfocusedCustomColor",
        "workspaceUrgentColorMode", "workspaceUrgentCustomColor", "workspaceFocusedBorderEnabled",
        "workspaceFocusedBorderColor", "workspaceFocusedBorderCustomColor", "workspaceFocusedBorderThickness",
        "iconThemeDark", "iconThemeLight", "iconThemePerMode", "cursorSettings",
        "launcherLogoMode", "launcherLogoCustomPath", "launcherLogoColorOverride",
        "launcherLogoColorInvertOnMode", "launcherLogoBrightness", "launcherLogoContrast", "launcherLogoSizeOffset",
        "fontFamily", "monoFontFamily", "fontWeight", "fontScale", "textRenderType", "textRenderQuality",
        "dankLauncherV2BorderEnabled", "dankLauncherV2BorderThickness", "dankLauncherV2BorderColor",
        "dockIconSize", "dockSpacing", "dockMargin", "dockBottomGap", "dockIndicatorStyle",
        "dockBorderEnabled", "dockBorderColor", "dockBorderOpacity", "dockBorderThickness",
        "notificationPopupShadowEnabled", "notificationForegroundLayers", "modalDarkenBackground",
        "frameEnabled", "frameMode", "frameThickness", "frameRounding", "frameColor", "frameOpacity",
        "frameBarSize", "frameBlurEnabled", "frameCloseGaps", "frameShowOnOverview",
        "barInsetPaddingShared", "barInsetPaddingSyncAll", "frameBarInsetPadding",
        // positions and grid live in SessionData, see snapshot() and applyProfile()
        "desktopWidgetInstances",
        // DMS 2.0 (settings version 42). Some replace keys above (radius,
        // animation speeds, dock); snapshot() only takes keys the running DMS has.
        "radiusStrength", "radiusMode", "fixedRadius",
        "animationDuration", "popoutAnimationDuration", "modalAnimationDuration", "notificationAnimationDuration",
        "dockConfigs", "blurStrength", "blurBorderSeeded", "containerSaturation", "displayFontFamily",
        "hostSurfaceColor", "hostSurfaceCustomColor", "cardSurfaceColor", "cardSurfaceCustomColor",
        "chipSurfaceColor", "chipSurfaceCustomColor", "chipSurfaceNestedColor", "chipSurfaceNestedCustomColor",
        "matugenSeedColor", "matugenSpec", "terminalOpacity", "terminalPalette"
    ]

    // DMS 2.0 computes cornerRadius from these three and no longer lets it be set
    readonly property bool radiusFromStrength: SettingsData.radiusStrength !== undefined

    // Bar keys that stay out of a profile: identity and monitor assignment.
    // `enabled` stays out on purpose, a profile without a bar would be hard to undo.
    readonly property var barSkipKeys: ["id", "name", "enabled", "screenPreferences", "showOnLastDisplay"]
    // Stored next to the bar values: whether the bar is on in this profile. Only
    // applied to extra bars; the first bar and islands always stay on.
    readonly property string barActiveKey: "_profileActive"

    // In connected frame mode DMS zeroes these bar values and keeps the originals
    // in connectedFrameBarStyleBackups. That sync does not run on a reload from
    // disk, so frame, backups and bar values have to be written consistently.
    readonly property var barFrameManaged: ["shadowIntensity", "squareCorners", "attachToScreenEdge", "gothCornersEnabled", "borderEnabled"]

    readonly property var _settings: SettingsData.pluginSettings
    function cfg(key, fallback) {
        return SettingsData.getPluginSetting("dmsProfiles", key, fallback);
    }

    // Plugins whose settings belong to a profile, e.g. ["audioFx"]
    readonly property var profilePlugins: {
        root._settings;
        const v = cfg("profilePlugins", []);
        return Array.isArray(v) ? v : String(v).split(",").map(s => s.trim()).filter(s => s.length > 0);
    }
    // Optional shell commands for things outside DMS (terminal colors, compositor
    // extras). The save command prints JSON that is stored as `extras`. The apply
    // command starts as soon as the new settings.json is written, while DMS
    // reloads it and the colors are generated; the new desktop is shown when
    // both are done. It gets
    // DMS_PROFILE_DIR, DMS_PROFILE_SLUG, DMS_PROFILE_NAME and
    // DMS_PROFILE_NEW_COLORS (1 if new colors are being generated, else 0).
    readonly property string saveCommand: {
        root._settings;
        return cfg("saveCommand", "");
    }
    readonly property string applyCommand: {
        root._settings;
        return cfg("applyCommand", "");
    }
    readonly property bool autosave: {
        root._settings;
        return cfg("autosave", true);
    }
    // Switch to the original wallpaper file while it exists, not to the copy in
    // the profile folder. Then DMS and the wallpaper plugins see the folder the
    // picture really lives in (cycling, carousel). The copy is the fallback.
    readonly property bool useOriginalWallpaper: {
        root._settings;
        return cfg("useOriginalWallpaper", true);
    }

    function clone(v) {
        return v === undefined ? undefined : JSON.parse(JSON.stringify(v));
    }

    ProfileStore {
        id: store
    }

    // ------------------------------------------------------------------ migration
    // Profiles from an older settings format (DMS 1.6 under DMS 2.0) go through
    // DMS' own migration, see ProfileMigration.js. Under DMS 1.6 nothing runs.
    readonly property int settingsVersion: SettingsData.settingsConfigVersion || 0
    // false until the profiles on disk are in the running format; autosave
    // waits for it, so no old profile is overwritten before it is converted
    property bool migrationDone: root.settingsVersion <= Migration.baseVersion
    // The active profile was converted, but the running settings are DMS' own
    // migration of settings.json, which loses the frame opacity. So the active
    // profile is applied once right after the conversion. Autosave stays off
    // until that has worked (or a profile has been applied or saved by hand).
    property bool pausedByMigration: false
    property string migrationApplySlug: ""
    property var migrationLog: []
    property var _dmsSettingsStore: null

    // DMS' SettingsStore.js from the running shell, loaded on first use
    function settingsStore() {
        if (root._dmsSettingsStore)
            return root._dmsSettingsStore;
        const dir = "file://" + Theme.shellDir + "/Common/settings/";
        try {
            root._dmsSettingsStore = Qt.createQmlObject("import QtQml\n" + "import \"" + dir + "SettingsStore.js\" as Store\n" + "import \"" + dir + "SettingsSpec.js\" as Spec\n" + "import \"" + dir + "BarWidgetDefaults.js\" as Widgets\n" + "QtObject {\n" + "    readonly property var migratedGlobals: Widgets.MIGRATED_GLOBALS\n" + "    function migrate(obj, version) { return Store.migrateToVersion(obj, version); }\n" + "    function known(key) { return Spec.SPEC[key] !== undefined; }\n" + "}\n", root, "dmsProfilesSettingsStore");
        } catch (e) {
            console.warn("Profiles: could not load the DMS settings migration:", e);
        }
        return root._dmsSettingsStore;
    }

    // The profile's dms part in the running format; unchanged when it already is
    function migratedDms(dms, slug) {
        if (!Migration.needsMigration(dms, root.settingsVersion))
            return dms;
        const st = root.settingsStore();
        let r = null;
        try {
            r = st ? Migration.migrate(dms, root.settingsVersion, st, SettingsData.barConfigs) : null;
        } catch (e) {
            console.warn("Profiles: migrating", slug, "failed:", e);
        }
        if (!r)
            return dms;
        const line = slug + ": settings " + r.from + " -> " + root.settingsVersion + (r.notes.length ? " (" + r.notes.join("; ") + ")" : "");
        // the start copy of a profile gives the same line a second time
        if (root.migrationLog.indexOf(line) < 0) {
            console.info("Profiles:", line);
            root.migrationLog = root.migrationLog.concat([line]);
        }
        return r.dms;
    }

    // Applies the converted active profile once. Waits a moment so the shell
    // has finished starting; a switch that is still busy is tried again.
    Timer {
        id: migrationApply
        interval: 3000
        property int tries: 0
        onTriggered: {
            const slug = root.migrationApplySlug;
            if (!slug)
                return;
            const r = root.apply(slug);
            if (r === "started")
                return;
            if (r === "busy" && ++tries < 5) {
                restart();
                return;
            }
            root.migrationApplied(false);
        }
    }

    function migrationApplied(ok) {
        root.migrationApplySlug = "";
        if (ok) {
            ToastService.showInfo(I18n.trFor("dmsProfiles", "Profiles converted for the new DMS version"), I18n.trFor("dmsProfiles", "The active profile was applied again."));
        } else {
            root.pausedByMigration = true;
            ToastService.showWarning(I18n.trFor("dmsProfiles", "Profiles converted for the new DMS version"), I18n.trFor("dmsProfiles", "The active profile could not be applied. Its changes are not saved until a profile is applied."));
        }
    }

    Connections {
        target: root
        function onSwitched(slug, ok) {
            if (root.migrationApplySlug !== "" && slug === root.migrationApplySlug)
                root.migrationApplied(ok);
        }
    }

    // Once after an update of DMS: rewrite every profile in the new format and
    // keep the original next to it as profile.v<old version>.json
    function migrateProfiles() {
        if (root.migrationDone)
            return;
        const slugs = store.profiles.filter(p => p.oldFormat).map(p => p.slug);
        const active = store.activeSlug;
        let converted = 0;
        const next = i => {
            if (i >= slugs.length) {
                root.migrationDone = true;
                if (converted === 0)
                    return;
                store.refresh();
                if (root.pausedByMigration) {
                    migrationApply.tries = 0;
                    root.migrationApplySlug = active;
                    migrationApply.restart();
                } else {
                    ToastService.showInfo(I18n.trFor("dmsProfiles", "Profiles converted for the new DMS version"));
                }
                return;
            }
            store.migrate(slugs[i], dms => root.migratedDms(dms, slugs[i]), done => {
                if (done) {
                    converted++;
                    if (slugs[i] === active)
                        root.pausedByMigration = true;
                }
                next(i + 1);
            });
        };
        next(0);
    }

    // ------------------------------------------------------------------ snapshot
    function snapshot() {
        const settings = {};
        for (const k of root.visualKeys) {
            const v = SettingsData[k];
            if (v !== undefined && typeof v !== "function")
                settings[k] = root.clone(v);
        }
        const bars = {};
        for (const b of SettingsData.barConfigs) {
            const o = {};
            for (const k in b) {
                if (root.barSkipKeys.indexOf(k) < 0)
                    o[k] = root.clone(b[k]);
            }
            // Extra bars belong to the profile, on or off; see mergeSettings()
            o[root.barActiveKey] = b.enabled !== false;
            bars[b.id] = o;
        }
        const plugins = {};
        for (const id of root.profilePlugins)
            plugins[id] = SettingsData.getPluginSettingsForPlugin(id);
        return {
            // Settings format the values were taken from, for migrating old profiles
            "configVersion": SettingsData.settingsConfigVersion,
            "settings": settings,
            "bars": bars,
            "plugins": plugins,
            "session": root.sessionSnapshot()
        };
    }

    // With a wallpaper per monitor or per light/dark mode, wallpaperPath alone
    // is not what is shown (issue #1). The maps are only taken when the mode is
    // on; otherwise DMS keeps stale values in them.
    function sessionSnapshot() {
        const s = {
            "wallpaperPath": SessionData.wallpaperPath,
            "isLightMode": SessionData.isLightMode,
            "desktopWidgetInstancePositions": root.clone(SessionData.desktopWidgetInstancePositions),
            "desktopWidgetGridSettings": root.clone(SessionData.desktopWidgetGridSettings),
            "perMonitorWallpaper": SessionData.perMonitorWallpaper === true,
            "perModeWallpaper": SessionData.perModeWallpaper === true
        };
        if (s.perMonitorWallpaper)
            s.monitorWallpapers = root.clone(SessionData.monitorWallpapers || {});
        if (s.perModeWallpaper && s.perMonitorWallpaper) {
            s.monitorWallpapersLight = root.clone(SessionData.monitorWallpapersLight || {});
            s.monitorWallpapersDark = root.clone(SessionData.monitorWallpapersDark || {});
        } else if (s.perModeWallpaper) {
            s.wallpaperPathLight = SessionData.wallpaperPathLight || "";
            s.wallpaperPathDark = SessionData.wallpaperPathDark || "";
        }
        return s;
    }

    // Calls back with the extras object, or undefined when no save command is set
    function captureExtras(callback) {
        if (!root.saveCommand) {
            callback(undefined);
            return;
        }
        Proc.runCommand("dmsProfiles.saveCommand", ["sh", "-c", root.saveCommand], (out, code) => {
            let extras = null;
            if (code === 0) {
                try {
                    extras = JSON.parse(String(out).trim());
                } catch (e) {
                    console.warn("Profiles: save command did not print JSON");
                }
            }
            callback(extras);
        }, 0, 15000);
    }

    function saveCurrent(slug, name, callback) {
        root.captureExtras(extras => store.save(slug, name, root.snapshot(), extras, callback));
    }

    function create(name, callback) {
        const n = String(name).trim();
        const slug = store.slugify(n);
        if (!n || !slug) {
            callback && callback("empty");
            return;
        }
        if (store.find(slug)) {
            callback && callback("exists");
            return;
        }
        root.saveCurrent(slug, n, () => store.setActive(slug, () => store.writeStart(slug, () => {
                    root.pausedByError = false;
                    root.pausedByMigration = false;
                    callback && callback("");
                })));
    }

    // ------------------------------------------------------------------ autosave
    // Changes made in the settings go into the active profile after a short calm
    // period. Paused while switching and after a failed switch, so a half applied
    // state never ends up in a profile.
    property bool switching: false
    property bool pausedByError: false

    function autosaveNow(callback) {
        const slug = store.activeSlug;
        const entry = store.find(slug);
        if (!root.autosave || root.switching || root.pausedByError || root.pausedByMigration || !root.migrationDone || !entry) {
            callback && callback(false);
            return;
        }
        const stored = store.load(slug);
        if (!stored) {
            callback && callback(false);
            return;
        }
        const snap = root.snapshot();
        root.captureExtras(extras => {
            const sameDms = store.stable(snap) === store.stable(stored.dms);
            const sameExtras = extras === undefined || store.stable(extras) === store.stable(stored.extras);
            if (sameDms && sameExtras) {
                callback && callback(false);
                return;
            }
            store.save(slug, stored.name || entry.name, snap, extras, () => callback && callback(true));
        });
    }

    Timer {
        id: autosaveTimer
        interval: 3000
        onTriggered: root.autosaveNow()
    }

    function scheduleAutosave() {
        if (root.autosave && !root.switching)
            autosaveTimer.restart();
    }

    Connections {
        target: SettingsData
        function onPluginSettingsChanged() {
            root.scheduleAutosave();
        }
    }

    FileView {
        path: Paths.strip(Paths.config) + "/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: root.scheduleAutosave()
    }

    FileView {
        path: Paths.strip(Paths.state) + "/session.json"
        watchChanges: true
        printErrors: false
        onFileChanged: root.scheduleAutosave()
    }

    // Extras (e.g. terminal transparency) change outside DMS; compare them now and then
    Timer {
        interval: 30000
        repeat: true
        running: root.autosave && root.saveCommand !== ""
        onTriggered: root.autosaveNow()
    }

    Component.onCompleted: store.refresh(() => root.migrateProfiles())

    // ------------------------------------------------------------------ switching
    FileView {
        id: settingsFile
        path: Paths.strip(Paths.config) + "/settings.json"
        blockLoading: true
        printErrors: false
    }

    function connected(s) {
        return !!s.frameEnabled && (s.frameMode === undefined || s.frameMode === "connected");
    }

    function mergeSettings(current, dms) {
        const oldBackups = current.connectedFrameBarStyleBackups || {};
        const wasConnected = root.connected(current);
        const want = dms.settings || {};
        const oldInstances = current.desktopWidgetInstances;
        const oldDocks = current.dockConfigs;
        for (const k in want)
            current[k] = want[k];
        if (Array.isArray(want.desktopWidgetInstances) && Array.isArray(oldInstances))
            current.desktopWidgetInstances = root.mergeWidgetInstances(oldInstances, want.desktopWidgetInstances);
        if (Array.isArray(want.dockConfigs) && Array.isArray(oldDocks))
            current.dockConfigs = root.mergeDocks(oldDocks, want.dockConfigs);
        const bars = dms.bars || {};
        const all = current.barConfigs || [];
        for (let i = 0; i < all.length; i++) {
            const bar = all[i];
            const upd = bars[bar.id] || {};
            for (const k in upd) {
                if (root.barSkipKeys.indexOf(k) < 0 && k !== root.barActiveKey)
                    bar[k] = upd[k];
            }
            // Extra bars follow the profile: on as saved, off when the profile
            // does not know them. Older profiles saved a bar without the flag,
            // that counts as on. The first bar and islands are never switched off.
            if (i > 0 && bar.island !== true)
                bar.enabled = bars[bar.id] ? upd[root.barActiveKey] !== false : false;
        }
        if (!root.connected(current)) {
            current.connectedFrameBarStyleBackups = {};
        } else if (want.connectedFrameBarStyleBackups === undefined) {
            const backups = wasConnected ? oldBackups : {};
            for (const bar of (current.barConfigs || [])) {
                if (backups[bar.id] !== undefined)
                    continue;
                const src = bars[bar.id] || bar;
                const b = {};
                for (const k of root.barFrameManaged)
                    b[k] = src[k] !== undefined ? src[k] : bar[k];
                backups[bar.id] = b;
            }
            current.connectedFrameBarStyleBackups = backups;
        }
        if (root.connected(current)) {
            for (const bar of (current.barConfigs || [])) {
                bar.shadowIntensity = 0;
                bar.squareCorners = false;
                bar.attachToScreenEdge = false;
                bar.gothCornersEnabled = false;
                bar.borderEnabled = false;
            }
        }
        return current;
    }

    // DMS 2.0 keeps docks as a list like the bars. A profile sets the look of
    // the docks it knows; whether a dock is on and where it shows stays as is.
    function mergeDocks(current, wanted) {
        return current.map(dock => {
            const want = wanted.find(w => w && w.id === dock.id);
            if (!want)
                return dock;
            const out = Object.assign({}, dock);
            for (const k in want) {
                if (root.barSkipKeys.indexOf(k) < 0)
                    out[k] = want[k];
            }
            return out;
        });
    }

    // Widgets the profile does not know stay in the list, switched off, and the
    // current order is kept. DMS rebuilds every desktop widget as soon as the
    // set of instances or their order changes (DesktopWidgetLayer
    // orderSignature); switching on and off only shows and hides. Replacing
    // the whole list blocks the shell for up to 1.7 s when the two profiles
    // have different widgets.
    function mergeWidgetInstances(current, wanted) {
        const byId = {};
        for (const w of wanted)
            byId[w.id] = w;
        const result = [];
        for (const inst of current) {
            if (byId[inst.id]) {
                result.push(byId[inst.id]);
                delete byId[inst.id];
            } else {
                const off = root.clone(inst);
                off.enabled = false;
                result.push(off);
            }
        }
        for (const w of wanted) {
            if (byId[w.id])
                result.push(w);
        }
        return result;
    }

    function settingsLoaded(dms) {
        const want = dms.settings || {};
        const radiusKeys = root.radiusFromStrength ? ["radiusStrength", "radiusMode", "fixedRadius"] : ["cornerRadius"];
        for (const k of radiusKeys.concat(["registryThemeVariants", "popupTransparency", "frameEnabled"])) {
            if (want[k] !== undefined && store.stable(SettingsData[k]) !== store.stable(want[k]))
                return false;
        }
        const bars = dms.bars || {};
        for (const bar of SettingsData.barConfigs) {
            const b = bars[bar.id];
            if (b && b.position !== undefined && b.position !== bar.position)
                return false;
        }
        return true;
    }

    function writeSettingsText(text, callback) {
        // DMS 1.6 skips the next file change while _selfWrite is set and can
        // leave it set after a save that wrote nothing. DMS 2.0 no longer has it.
        if (SettingsData._selfWrite !== undefined)
            SettingsData._selfWrite = false;
        const path = settingsFile.path;
        // Write in place: DMS watches the file entry, a renamed-over file is not noticed
        Proc.runCommand("dmsProfiles.writeSettings", ["sh", "-c", "printf %s " + store.quote(Qt.btoa(text)) + " | base64 -d > " + store.quote(path + ".profiles-tmp") + " && cat " + store.quote(path + ".profiles-tmp") + " > " + store.quote(path) + " && rm -f " + store.quote(path + ".profiles-tmp")], (out, code) => callback(code === 0), 0, 10000);
    }

    // Applies what DMS skips when it reloads settings.json from disk
    function applyProfile(p, wallpaper, slug) {
        const d = p.dms || {};
        SettingsData.applyStoredTheme();
        // applyStoredTheme only reloads a custom theme when its name or file
        // changed, not when only the variant (accent) did
        if (typeof Theme.reloadCustomThemeVariant === "function")
            Theme.reloadCustomThemeVariant();
        SettingsData.updateCompositorLayout();

        if (d.session && d.session.desktopWidgetInstancePositions !== undefined) {
            SessionData.desktopWidgetInstancePositions = root.clone(d.session.desktopWidgetInstancePositions);
            if (d.session.desktopWidgetGridSettings !== undefined)
                SessionData.desktopWidgetGridSettings = root.clone(d.session.desktopWidgetGridSettings);
            SessionData.saveSettings();
        }

        // DMS does not reload plugin_settings.json from disk, so set from inside
        if (d.plugins) {
            for (const id in d.plugins) {
                const want = d.plugins[id];
                const have = SettingsData.getPluginSettingsForPlugin(id);
                for (const k in want) {
                    if (JSON.stringify(have[k]) !== JSON.stringify(want[k]))
                        SettingsData.setPluginSetting(id, k, root.clone(want[k]));
                }
            }
        }

        // Also set the system color scheme. Otherwise the previous value stays
        // there, and the portal sync flips the profile back while DMS
        // regenerates colors.
        const light = d.session ? d.session.isLightMode === true : false;
        root.wantLight = light;
        PortalService.setSystemColorScheme(light);
        if (light !== SessionData.isLightMode)
            Theme.setLightMode(light);
        lightGuard.rounds = 0;
        lightGuard.restart();

        const s = d.session || {};
        if (s.perMonitorWallpaper !== undefined) {
            if (root.applyWallpapers(p, slug, wallpaper))
                SessionData.wallpaperCyclingFolderPath = "";
            SessionData.saveSettings();
            Theme.generateSystemThemesFromCurrentTheme();
        } else if (wallpaper && wallpaper !== SessionData.wallpaperPath) {
            // profile from before the wallpaper modes were saved
            root.quietWallpaperTransition();
            SessionData.setWallpaper(wallpaper);
            SessionData.wallpaperCyclingFolderPath = "";
            SessionData.saveSettings();
        } else {
            Theme.generateSystemThemesFromCurrentTheme();
        }
    }

    // Under the overlay the DMS wallpaper transition is not visible and only adds waiting time
    function quietWallpaperTransition() {
        if (transition.state !== "idle" && SessionData.wallpaperTransition !== "none") {
            restoreWallpaperTransition.value = SessionData.wallpaperTransition;
            SessionData.wallpaperTransition = "none";
            restoreWallpaperTransition.restart();
        }
    }

    // Sets wallpaper, per-monitor and per-mode wallpapers as saved, with the
    // copies in the profile folder. Set directly instead of through
    // setMonitorWallpaper and friends: those save and regenerate the colors
    // once per call. Returns true if anything changed.
    function applyWallpapers(p, slug, wallpaper) {
        const s = p.dms.session;
        const res = path => root.wallpaperFile(slug, p, path);
        const resMap = map => {
            const out = {};
            for (const k in (map || {}))
                out[k] = res(map[k]);
            return out;
        };
        const perMonitor = s.perMonitorWallpaper === true;
        const perMode = s.perModeWallpaper === true;
        // maps first, the two switches last, so nothing is drawn from a half set state
        const want = {};
        if (perMonitor)
            want.monitorWallpapers = resMap(s.monitorWallpapers);
        want.wallpaperPath = wallpaper || res(s.wallpaperPath || "") || SessionData.wallpaperPath;
        // per mode, what is shown is the picture of the profile's mode, as DMS
        // would pick it (syncWallpaperForCurrentMode), not the main wallpaper
        if (perMode && perMonitor) {
            want.monitorWallpapersLight = resMap(s.monitorWallpapersLight);
            want.monitorWallpapersDark = resMap(s.monitorWallpapersDark);
            const shown = root.wantLight ? want.monitorWallpapersLight : want.monitorWallpapersDark;
            if (Object.keys(shown).length > 0)
                want.monitorWallpapers = Object.assign({}, shown);
        } else if (perMode) {
            want.wallpaperPathLight = res(s.wallpaperPathLight || "");
            want.wallpaperPathDark = res(s.wallpaperPathDark || "");
            want.wallpaperPath = (root.wantLight ? want.wallpaperPathLight : want.wallpaperPathDark) || want.wallpaperPath;
        }
        want.perMonitorWallpaper = perMonitor;
        want.perModeWallpaper = perMode;
        // maps the profile does not use are emptied after the switches; left
        // behind they pointed at other profiles' (maybe deleted) pictures
        if (!perMonitor)
            want.monitorWallpapers = {};
        if (!(perMode && perMonitor)) {
            want.monitorWallpapersLight = {};
            want.monitorWallpapersDark = {};
        }
        if (!perMode || perMonitor) {
            want.wallpaperPathLight = "";
            want.wallpaperPathDark = "";
        }
        let changed = false;
        for (const k in want) {
            if (store.stable(SessionData[k]) !== store.stable(want[k])) {
                if (!changed)
                    root.quietWallpaperTransition();
                changed = true;
                SessionData[k] = want[k];
            }
        }
        return changed;
    }

    // Light/dark can still flip in the first seconds (portal sync, delayed GTK
    // switch). Put it back to the profile value.
    property bool wantLight: false
    Timer {
        id: lightGuard
        property int rounds: 0
        interval: 500
        repeat: true
        onTriggered: {
            rounds++;
            const busy = typeof Theme.workerRunning === "boolean" && Theme.workerRunning;
            if (Theme.isLightMode !== root.wantLight && !busy) {
                PortalService.setSystemColorScheme(root.wantLight);
                Theme.setLightMode(root.wantLight);
            }
            if (rounds >= 8)
                stop();
        }
    }

    Timer {
        id: restoreWallpaperTransition
        interval: 3000
        property string value: ""
        onTriggered: {
            if (value)
                SessionData.setWallpaperTransition(value);
            value = "";
        }
    }

    // The switch runs as a chain of steps; each waits for the previous one.
    property string pendingSlug: ""
    // Original wallpaper paths of the pending profile that still exist
    property var originalsFound: ({})
    // False while the check runs; the switch waits for it, or it could apply the
    // copy and the next autosave would store the copy's path
    property bool originalsReady: true

    // Looks, while the switch starts, which original wallpaper files are still
    // there. Answers long before the wallpaper is applied; until then (or when
    // the option is off) the copies are used.
    function findOriginals(p) {
        root.originalsFound = {};
        root.originalsReady = !root.useOriginalWallpaper;
        if (!root.useOriginalWallpaper)
            return;
        const main = store.mainWallpaper(p.dms.session);
        const paths = [main].concat(store.otherWallpapers(p.dms.session, main)).filter(v => v && !String(v).startsWith("#") && !String(v).startsWith(store.root + "/"));
        if (paths.length === 0) {
            root.originalsReady = true;
            return;
        }
        const slug = root.pendingSlug;
        store.sh(paths.map(v => "[ -f " + store.quote(v) + " ] && printf '%s\\n' " + store.quote(v) + "; ").join("") + "true", out => {
            if (root.pendingSlug !== slug)
                return;
            const found = {};
            String(out).split("\n").filter(v => v).forEach(v => found[v] = true);
            root.originalsFound = found;
            root.originalsReady = true;
        });
    }

    // The file to show for a saved wallpaper path: the original if the option is
    // on and it exists, else the copy in the profile folder (`copy` when the
    // profile has no list of copies), else the path itself
    function wallpaperFile(slug, p, path, copy) {
        if (path && root.useOriginalWallpaper && root.originalsFound[path])
            return path;
        const saved = store.resolveWallpaper(slug, p, path);
        return saved !== path || !copy ? saved : copy;
    }
    property var pendingProfile: null
    property bool pendingSameColors: false
    property real appliedAt: 0
    property int loadRetries: 0
    property string lastError: ""
    // Milliseconds of each step of the last switch, reported by `status`
    property var timings: ({})
    property real startedAt: 0
    function mark(step) {
        const t = Object.assign({}, root.timings);
        t[step] = Date.now() - root.startedAt;
        root.timings = t;
    }

    signal switched(string slug, bool ok)

    function apply(slug) {
        if (root.switching)
            return "busy";
        const entry = store.find(slug);
        if (!entry)
            return "unknown profile";
        root.hidePicker();
        autosaveTimer.stop();
        root.autosaveNow(() => {
            const p = store.load(slug);
            if (!p || !p.dms) {
                root.lastError = "profile file unreadable";
                root.switched(slug, false);
                return;
            }
            // normally done once at start; a profile copied in later is
            // converted here, in memory only
            p.dms = root.migratedDms(p.dms, slug);
            root.switching = true;
            root.startedAt = Date.now();
            root.timings = {};
            root.colorsDone = false;
            root.commandDone = false;
            root.appliedAt = 0;
            root.pendingSlug = slug;
            root.pendingProfile = p;
            root.findOriginals(p);
            root.lastError = "";
            const want = p.dms.settings || {};
            const wantLight = p.dms.session ? p.dms.session.isLightMode === true : false;
            root.pendingSameColors = store.stable(SettingsData.registryThemeVariants) === store.stable(want.registryThemeVariants) && SettingsData.currentThemeName === want.currentThemeName && SessionData.isLightMode === wantLight;
            // Two-phase: the animation runs onto the new wallpaper right away
            // and does not wait for the profile (see ProfileTransition.qml)
            const wall = p.wallpaper ? store.dir(slug) + "/" + p.wallpaper : "";
            if (transition.cover(false, wall) === "started")
                coverWait.restart();
            else
                root.stepWrite();
        });
        return "started";
    }

    Timer {
        id: coverWait
        interval: 10
        repeat: true
        property int ticks: 0
        onRunningChanged: if (running) ticks = 0
        onTriggered: {
            ticks++;
            // two-phase: the animation may already run or even be done
            if (transition.state !== "capturing" || ticks > 300) {
                stop();
                root.mark("covered");
                if (transition.twoPhase && transition.state === "covered")
                    transition.reveal("");
                root.stepWrite();
            }
        }
    }

    function stepWrite() {
        settingsFile.reload();
        settingsFile.waitForJob();
        let current;
        try {
            current = JSON.parse(settingsFile.text());
        } catch (e) {
            root.fail("settings.json unreadable");
            return;
        }
        const merged = root.mergeSettings(current, root.pendingProfile.dms);
        root.pendingText = JSON.stringify(merged, null, 2) + "\n";
        root.loadRetries = 0;
        root.mark("merged");
        root.startEarlyColors(root.pendingProfile.dms);
        root.writeSettingsText(root.pendingText, ok => {
            root.mark("written");
            if (!ok) {
                root.fail("could not write settings.json");
                return;
            }
            // The apply command only needs the written file and waits for the
            // colors itself, so it starts here and not after DMS has reloaded
            // (up to 0.3 s less per switch).
            root.commandDone = false;
            root.startCommand();
            loadWait.restart();
        });
    }
    property string pendingText: ""

    // Colors first: matugen needs the theme values only, not the whole
    // settings.json. Set them directly (DMS does not save on a plain property
    // change) and start the generation, so it runs while DMS reloads the
    // settings instead of after. Only when nothing else feeds into the colors
    // changes; otherwise the colors are generated after DMS has reloaded.
    property bool earlyColors: false
    property bool earlyColorsDone: false
    readonly property var earlyColorBlockers: ["customThemeFile", "matugenScheme", "matugenContrast", "matugenSourceMode", "matugenSmartMode", "terminalsAlwaysDark", "runUserMatugenTemplates"]
    function startEarlyColors(dms) {
        root.earlyColors = false;
        root.earlyColorsDone = false;
        if (root.pendingSameColors)
            return;
        const want = dms.settings || {};
        const wantLight = dms.session ? dms.session.isLightMode === true : false;
        if (wantLight !== SessionData.isLightMode)
            return;
        for (const k of root.earlyColorBlockers) {
            if (want[k] !== undefined && store.stable(want[k]) !== store.stable(SettingsData[k]))
                return;
        }
        if (want.registryThemeVariants !== undefined)
            SettingsData.registryThemeVariants = root.clone(want.registryThemeVariants);
        if (want.currentThemeCategory !== undefined)
            SettingsData.currentThemeCategory = want.currentThemeCategory;
        if (want.currentThemeName !== undefined && want.currentThemeName !== SettingsData.currentThemeName)
            SettingsData.currentThemeName = want.currentThemeName;
        root.earlyColors = true;
        SettingsData.applyStoredTheme();
        if (typeof Theme.reloadCustomThemeVariant === "function")
            Theme.reloadCustomThemeVariant();
        Theme.generateSystemThemesFromCurrentTheme();
        root.mark("early");
    }

    Timer {
        id: loadWait
        interval: 50
        repeat: true
        property int ticks: 0
        onRunningChanged: if (running) ticks = 0
        onTriggered: {
            ticks++;
            if (root.originalsReady && root.settingsLoaded(root.pendingProfile.dms)) {
                stop();
                root.mark("loaded");
                root.stepApply();
                return;
            }
            if (ticks === 80 && root.loadRetries === 0) {
                root.loadRetries = 1;
                root.writeSettingsText(root.pendingText, () => {});
            }
            if (ticks > 240) {
                stop();
                root.fail("DMS did not load the profile values");
            }
        }
    }

    function stepApply() {
        const p = root.pendingProfile;
        const copy = p.wallpaper ? store.dir(root.pendingSlug) + "/" + p.wallpaper : "";
        const wall = root.wallpaperFile(root.pendingSlug, p, store.mainWallpaper(p.dms.session), copy);
        root.applyProfile(p, wall, root.pendingSlug);
        root.mark("applied");
        root.appliedAt = Date.now();
        root.colorsDone = false;
        colorsWait.fired = false;
        // the early generation already delivered the new colors
        colorsWait.interval = root.earlyColorsDone ? 40 : (root.pendingSameColors ? 1200 : 20000);
        colorsWait.restart();
    }

    FileView {
        path: Paths.strip(Paths.cache) + "/dms-colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            if (root.switching && root.timings.colorsFile === undefined)
                root.mark("colorsFile");
            if (root.earlyColors && !root.earlyColorsDone && root.switching) {
                root.earlyColorsDone = true;
                root.mark("colorsEarly");
            }
            if (colorsWait.running && !colorsWait.fired) {
                // matugen writes several files one after another
                colorsWait.fired = true;
                colorsWait.interval = 40;
                colorsWait.restart();
            }
        }
    }

    Timer {
        id: colorsWait
        property bool fired: false
        onTriggered: {
            root.mark("colors");
            root.colorsDone = true;
            root.maybeReveal();
        }
    }

    property bool colorsDone: false
    property bool commandDone: false

    function startCommand() {
        if (!root.applyCommand) {
            root.commandDone = true;
            return;
        }
        const d = store.dir(root.pendingSlug);
        const name = root.pendingProfile.name || root.pendingSlug;
        const script = "export DMS_PROFILE_DIR=" + store.quote(d) + " DMS_PROFILE_SLUG=" + store.quote(root.pendingSlug) + " DMS_PROFILE_NAME=" + store.quote(name) + " DMS_PROFILE_NEW_COLORS=" + (root.pendingSameColors ? "0" : "1") + "; " + root.applyCommand;
        Proc.runCommand("dmsProfiles.applyCommand", ["sh", "-c", script], (out, code) => {
            if (code !== 0)
                console.warn("Profiles: apply command exited with", code, String(out).trim());
            root.mark("command");
            root.commandDone = true;
            root.maybeReveal();
        }, 0, 15000);
    }

    // two-phase: fade the overlay out (after the animation, if it still runs);
    // otherwise the classic reveal of the live screen
    function endCover() {
        if (transition.twoPhase)
            transition.uncover();
        else
            transition.reveal("");
    }

    function maybeReveal() {
        // appliedAt: the profile must be applied in THIS switch, the command can finish before that
        if (root.colorsDone && root.commandDone && root.appliedAt >= root.startedAt && !revealDelay.running && root.switching)
            root.stepReveal();
    }

    function stepReveal() {
        const rest = 250 - (Date.now() - root.appliedAt);
        revealDelay.interval = Math.max(1, rest);
        revealDelay.restart();
    }

    Timer {
        id: revealDelay
        onTriggered: {
            root.mark("revealed");
            root.endCover();
            const slug = root.pendingSlug;
            store.setActive(slug, () => store.writeStart(slug, () => {
                    root.pausedByError = false;
                    root.pausedByMigration = false;
                    // keep autosave paused until the light/dark guard is done
                    unpause.restart();
                    root.switched(slug, true);
                }));
        }
    }

    Timer {
        id: unpause
        interval: 4200
        onTriggered: root.switching = false
    }

    function fail(message) {
        console.warn("Profiles: switch failed:", message);
        root.lastError = message;
        root.pausedByError = true;
        root.switching = false;
        root.endCover();
        root.switched(root.pendingSlug, false);
        ToastService.showError(I18n.trFor("dmsProfiles", "Could not switch profile"), I18n.trFor("dmsProfiles", message));
    }

    function reset(slug) {
        const active = store.activeSlug === slug;
        store.restoreStart(slug, ok => {
            if (ok && active)
                root.apply(slug);
        });
    }

    ProfileTransition {
        id: transition
    }

    // ------------------------------------------------------------------ picker
    property int selected: 0
    property int gridColumns: 1

    // The picker shows profiles, or (wallpapers) the pictures in the folder of
    // the current wallpaper. The views read `profiles`, `selected` and
    // `choose` either way; items have slug, name, wallpaper, thumb and active.
    property bool wallpaperMode: false
    property var wallpaperItems: []
    // The picker leaves out hidden profiles, but always shows the active one
    readonly property var profiles: root.wallpaperMode ? root.wallpaperItems : store.profiles.filter(p => p.shown !== false || p.active)
    readonly property string activeLabel: root.wallpaperMode ? I18n.trFor("dmsProfiles", "current wallpaper") : I18n.trFor("dmsProfiles", "active profile")
    readonly property string emptyLabel: root.wallpaperMode ? I18n.trFor("dmsProfiles", "No pictures found in the wallpaper folder.") : I18n.trFor("dmsProfiles", "No profiles yet. Create one in Settings under Profiles.")
    readonly property string pickerView: {
        root._settings;
        return cfg("pickerView", "strip");
    }
    readonly property string pickerShape: {
        root._settings;
        return cfg("pickerShape", "portrait");
    }

    function choose(index) {
        if (index < 0 || index >= root.profiles.length)
            return;
        if (root.wallpaperMode) {
            root.setWallpaper(root.profiles[index].wallpaper);
            root.hidePicker();
            return;
        }
        root.apply(root.profiles[index].slug);
    }

    // Sets the picture like the DMS file browser does; autosave then stores it
    // in the active profile
    function setWallpaper(path) {
        SessionData.setWallpaper(path);
        SessionData.wallpaperCyclingFolderPath = "";
        SessionData.saveSettings();
    }

    // Opens the picker on the wallpaper folder of the active profile, else on
    // the pictures next to the current wallpaper
    function showWallpapers() {
        if (SessionData.perMonitorWallpaper === true)
            return "the wallpaper picker does not support a wallpaper per monitor";
        const cur = SessionData.wallpaperPath || store.mainWallpaper(root.snapshot().session);
        const entry = store.find(store.activeSlug);
        const dir = entry && entry.wallpaperFolder ? entry.wallpaperFolder.replace(/\/+$/, "") : cur.substring(0, cur.lastIndexOf("/"));
        if (!dir || (!entry?.wallpaperFolder && (!cur || cur.startsWith("#"))))
            return "no wallpaper picture";
        const exts = ["jpg", "jpeg", "png", "webp", "bmp", "gif", "avif", "jxl"];
        const test = exts.map(e => "-iname " + store.quote("*." + e)).join(" -o ");
        store.sh("find -L " + store.quote(dir) + " -maxdepth 1 -type f \\( " + test + " \\) | sort", out => {
            root.wallpaperItems = String(out).split("\n").filter(f => f).map(f => ({
                        "slug": f,
                        "name": f.substring(f.lastIndexOf("/") + 1).replace(/\.[^.]+$/, ""),
                        "wallpaper": f,
                        "thumb": f.split("/").map(encodeURIComponent).join("/"),
                        "active": f === cur,
                        "shown": true
                    }));
            root.wallpaperMode = true;
            root.selected = Math.max(0, root.wallpaperItems.findIndex(x => x.active));
            picker.visible = true;
            Qt.callLater(() => keyCatcher.forceActiveFocus());
        });
        return "started";
    }

    function showPicker() {
        root.wallpaperMode = false;
        store.refresh(() => {
            const active = root.profiles.findIndex(x => x.active);
            root.selected = active >= 0 ? active : 0;
        });
        picker.visible = true;
        Qt.callLater(() => keyCatcher.forceActiveFocus());
    }

    function hidePicker() {
        picker.visible = false;
        root.wallpaperMode = false;
    }

    PanelWindow {
        id: picker
        visible: false
        color: "transparent"

        WlrLayershell.namespace: "dms:profiles"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: picker.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, (root.pickerView === "carousel" || root.pickerView === "grid") ? 0.6 : (root.pickerView === "free" ? 0.5 : 0.35))

            MouseArea {
                anchors.fill: parent
                onClicked: root.hidePicker()
                property real accumulated: 0
                onWheel: wheel => {
                    accumulated += wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                    while (accumulated >= 120) {
                        root.selected = Math.max(0, root.selected - 1);
                        accumulated -= 120;
                    }
                    while (accumulated <= -120) {
                        root.selected = Math.min(root.profiles.length - 1, root.selected + 1);
                        accumulated += 120;
                    }
                }
            }
        }

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                const last = root.profiles.length - 1;
                const grid = root.pickerView === "grid";
                if (event.key === Qt.Key_Escape) {
                    root.hidePicker();
                } else if (grid && (event.key === Qt.Key_Up || event.key === Qt.Key_K)) {
                    root.selected = Math.max(0, root.selected - root.gridColumns);
                } else if (grid && (event.key === Qt.Key_Down || event.key === Qt.Key_J)) {
                    root.selected = Math.min(last, root.selected + root.gridColumns);
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_Up || event.key === Qt.Key_K || event.key === Qt.Key_PageUp) {
                    root.selected = Math.max(0, root.selected - 1);
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_PageDown) {
                    root.selected = Math.min(last, root.selected + 1);
                } else if (event.key === Qt.Key_Home) {
                    root.selected = 0;
                } else if (event.key === Qt.Key_End) {
                    root.selected = Math.max(0, last);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.choose(root.selected);
                } else {
                    return;
                }
                event.accepted = true;
            }
        }

        Loader {
            anchors.fill: parent
            active: picker.visible
            sourceComponent: root.pickerView === "carousel" ? carouselView : (root.pickerView === "grid" ? gridView : rowView)
        }

        Component {
            id: rowView
            PickerRow {
                ctl: root
                framed: root.pickerView !== "free"
                shape: root.pickerShape
            }
        }

        Component {
            id: carouselView
            PickerCarousel {
                ctl: root
                shape: root.pickerShape
            }
        }

        Component {
            id: gridView
            PickerGrid {
                ctl: root
                shape: root.pickerShape
            }
        }
    }

    Timer {
        id: previewTimer
        interval: 700
        property string type: ""
        onTriggered: transition.reveal(type)
    }

    // ------------------------------------------------------------------ IPC
    // dms ipc call profiles toggle | wallpapers | list | apply SLUG | create NAME | save
    //   rename SLUG NAME | folder SLUG PATH | remove SLUG | move SLUG left|right|N | reset SLUG
    //   previewTransition TYPE | setOption KEY VALUE | themeAuto on|off|status
    IpcHandler {
        target: "profiles"

        function toggle(): string {
            if (picker.visible)
                root.hidePicker();
            else
                root.showPicker();
            return picker.visible ? "open" : "closed";
        }

        function list(): string {
            return JSON.stringify(store.profiles);
        }

        // dms ipc call profiles folder SLUG /path/to/pictures  (empty path: back to
        // the folder of the current wallpaper). The picker opens on this folder.
        function folder(slug: string, path: string): string {
            if (!store.find(slug))
                return "no profile " + slug;
            let dir = path.replace(/\/+$/, "");
            if (dir.startsWith("~/"))
                dir = Quickshell.env("HOME") + dir.substring(1);
            if (dir && !dir.startsWith("/"))
                return "the folder must be an absolute path";
            store.setWallpaperFolder(slug, dir, err => {
                if (err)
                    console.warn("Profiles: folder failed:", err);
            });
            return "started";
        }

        // Picker of the pictures in the wallpaper folder of the active profile
        function wallpapers(): string {
            if (picker.visible) {
                root.hidePicker();
                return "closed";
            }
            return root.showWallpapers();
        }

        // dms ipc call profiles show SLUG true|false  (shown in the picker or not)
        function show(slug: string, on: string): string {
            if (!store.find(slug))
                return "no profile " + slug;
            store.setShown(slug, on !== "false");
            return slug + (on !== "false" ? " shown" : " hidden");
        }

        function refresh(): string {
            store.refresh();
            return "ok";
        }

        function status(): string {
            return JSON.stringify({
                "active": store.activeSlug,
                "switching": root.switching,
                "pausedByError": root.pausedByError,
                "pausedByMigration": root.pausedByMigration,
                "settingsVersion": root.settingsVersion,
                "migrated": root.migrationLog,
                "lastError": root.lastError,
                "transition": transition.state,
                "timings": root.timings
            });
        }

        function apply(slug: string): string {
            return root.apply(slug);
        }

        function create(name: string): string {
            root.create(name, err => {
                if (err)
                    console.warn("Profiles: create failed:", err);
            });
            return "started";
        }

        // Save the current look into the active profile right away
        function save(): string {
            if (!store.activeSlug)
                return "no active profile";
            const entry = store.find(store.activeSlug);
            root.saveCurrent(store.activeSlug, entry ? entry.name : store.activeSlug, () => store.writeStart(store.activeSlug));
            root.pausedByError = false;
            root.pausedByMigration = false;
            return "started";
        }

        function rename(slug: string, name: string): string {
            store.rename(slug, name, err => {
                if (err)
                    console.warn("Profiles: rename failed:", err);
            });
            return "started";
        }

        function remove(slug: string): string {
            store.remove(slug);
            return "started";
        }

        function move(slug: string, where: string): string {
            store.move(slug, where);
            return "started";
        }

        function reset(slug: string): string {
            root.reset(slug);
            return "started";
        }

        function snapshot(): string {
            return JSON.stringify(root.snapshot());
        }

        function previewTransition(type: string): string {
            const r = transition.cover(true);
            if (r !== "started")
                return r;
            previewTimer.type = type;
            previewTimer.restart();
            return "started";
        }

        function setOption(key: string, value: string): string {
            const allowed = ["useOriginalWallpaper", "transition", "transitionMs", "transitionGlow", "transitionPool", "pickerView", "pickerShape", "pickerGlow", "pickerRing", "pickerCheck", "pickerCornerTheme", "pickerCorner", "profilePlugins", "saveCommand", "applyCommand", "autosave"];
            if (allowed.indexOf(key) < 0)
                return "unknown key, allowed: " + allowed.join(", ");
            let v = value;
            // transitionPool is a list in the settings page; profilePlugins is a
            // comma separated string there, and a list here would leave the text
            // field unable to show it.
            if (key === "transitionPool")
                v = value.split(",").map(s => s.trim()).filter(s => s.length > 0);
            else if (value === "true" || value === "false")
                v = value === "true";
            else if (value !== "" && !isNaN(Number(value)) && key !== "saveCommand" && key !== "applyCommand")
                v = Number(value);
            SettingsData.setPluginSetting("dmsProfiles", key, v);
            return key + " = " + JSON.stringify(v);
        }

        // Activates a custom theme file and sets its variant (accent) for dark,
        // light or both, the same way the theme page does it
        function customTheme(file: string, themeId: string, darkFlavor: string, lightFlavor: string, accent: string, mode: string): string {
            if (["dark", "light", "both"].indexOf(mode) < 0)
                return "mode must be dark, light or both";
            if (mode !== "light")
                SettingsData.setRegistryThemeMultiVariant(themeId, darkFlavor, accent, "dark");
            if (mode !== "dark")
                SettingsData.setRegistryThemeMultiVariant(themeId, lightFlavor, accent, "light");
            if (SettingsData.customThemeFile !== file || Theme.currentThemeName !== "custom") {
                SettingsData.set("customThemeFile", file);
                Theme.switchTheme("custom", true, true);
            } else if (typeof Theme.reloadCustomThemeVariant === "function") {
                Theme.reloadCustomThemeVariant();
            }
            return "ok";
        }

        // DMS automatic light/dark switching overrides the mode stored in a profile
        function themeAuto(state: string): string {
            if (state === "on" || state === "off")
                SessionData.setThemeModeAutoEnabled(state === "on");
            return JSON.stringify({
                "enabled": SessionData.themeModeAutoEnabled,
                "mode": SessionData.themeModeAutoMode,
                "light": SessionData.isLightMode
            });
        }
    }
}

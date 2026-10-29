// Profiles on disk: <DMS config folder>/profiles/<slug>/ (~/.config/DankMaterialShell
// under DMS 1.6, ~/.config/dms under 2.0)
//   profile.json    name, created, updated, wallpaper file name, dms snapshot, extras,
//                   wallpaperFiles (original path -> copy, with a wallpaper per
//                   monitor or per light/dark mode)
//   wallpaper.<ext> copy of the wallpaper, so a profile does not depend on the
//                   original file staying where it was
//   wallpaper-<n>.<ext> copies of the further wallpapers (per monitor, per mode)
//   profile.v<n>.json the profile before it was converted to a newer DMS
//                   settings format (see ProfileMigration.js)
//   .start/         the profile as it was when it became active, for reset
// profiles/state.json holds the active slug and the manual order.
//
// File operations run through `sh` (mkdir, cp, cmp, mv, rm). JSON is written
// base64 encoded through the command line; Qt.btoa encodes UTF-8.

pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import "ProfileMigration.js" as Migration

Item {
    id: store

    // Keeps thumb.jpg (1280 px wide) next to each profile's wallpaper: made once,
    // again when the wallpaper is newer. vipsthumbnail, else ImageMagick, else
    // none (the picker then loads the full wallpaper). Prints ##thumb if present;
    // not @@@, the listing is split at newline + @@@.
    readonly property string thumbScript: "w=; for f in \"$d\"wallpaper.*; do [ -f \"$f\" ] && { w=\"$f\"; break; }; done; t=\"${d}thumb.jpg\"; " + "if [ -n \"$w\" ] && { [ ! -f \"$t\" ] || [ \"$w\" -nt \"$t\" ]; }; then " + "if command -v vipsthumbnail >/dev/null; then vipsthumbnail \"$w\" -s 1280 -o \"$t[Q=85]\" >/dev/null 2>&1; " + "elif command -v magick >/dev/null; then magick \"$w\" -resize 1280x \"$t\" 2>/dev/null; fi; fi; " + "[ -f \"$t\" ] && printf '\\n##thumb'; "
    readonly property string root: Paths.strip(Paths.config) + "/profiles"

    property var profiles: []
    // Slugs left out of the picker and the dashboard tab (still in Settings)
    property var hidden: []
    property string activeSlug: ""
    property var order: []
    property bool loaded: false

    signal changed

    function quote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function dir(slug) {
        return store.root + "/" + slug;
    }

    function slugify(name) {
        return String(name).normalize("NFKD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/ß/g, "ss").replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
    }

    // Stable JSON with sorted keys, for comparing snapshots
    function stable(v) {
        if (Array.isArray(v))
            return "[" + v.map(x => store.stable(x)).join(",") + "]";
        if (v && typeof v === "object")
            return "{" + Object.keys(v).sort().map(k => JSON.stringify(k) + ":" + store.stable(v[k])).join(",") + "}";
        return JSON.stringify(v === undefined ? null : v);
    }

    property int _seq: 0
    function sh(script, callback, timeoutMs) {
        store._seq++;
        Proc.runCommand("dmsProfiles.store." + store._seq, ["sh", "-c", script], (out, code) => {
            if (callback)
                callback(out, code);
        }, 0, timeoutMs || 30000);
    }

    function writeJson(path, obj, callback) {
        const text = JSON.stringify(obj, null, 2) + "\n";
        store.sh("printf %s " + store.quote(Qt.btoa(text)) + " | base64 -d > " + store.quote(path) + ".tmp && mv " + store.quote(path) + ".tmp " + store.quote(path), callback);
    }

    // ------------------------------------------------------------------ reading
    function refresh(callback) {
        const script = "mkdir -p " + store.quote(store.root) + "; " + "cat " + store.quote(store.root + "/state.json") + " 2>/dev/null; " + "for d in " + store.quote(store.root) + "/*/; do [ -f \"$d/profile.json\" ] || continue; " + "printf '\\n@@@%s\\n' \"$(basename \"$d\")\"; cat \"$d/profile.json\"; " + store.thumbScript + "if cmp -s \"$d/profile.json\" \"$d/.start/profile.json\" 2>/dev/null; then echo '@@@same'; fi; done";
        store.sh(script, (out, code) => {
            const parts = String(out).split("\n@@@");
            let state = {};
            try {
                state = JSON.parse(parts[0].trim() || "{}");
            } catch (e) {}
            const list = [];
            for (let i = 1; i < parts.length; i++) {
                const nl = parts[i].indexOf("\n");
                const slug = parts[i].substring(0, nl);
                let body = parts[i].substring(nl + 1);
                const same = body.trim().endsWith("@@@same");
                if (same)
                    body = body.substring(0, body.lastIndexOf("@@@same"));
                const hasThumb = body.trim().endsWith("##thumb");
                if (hasThumb)
                    body = body.substring(0, body.lastIndexOf("##thumb"));
                let p;
                try {
                    p = JSON.parse(body);
                } catch (e) {
                    continue;
                }
                const wall = p.wallpaper ? store.dir(slug) + "/" + p.wallpaper : "";
                list.push({
                    // saved under an older DMS settings format
                    "oldFormat": Migration.needsMigration(p.dms, SettingsData.settingsConfigVersion || 0),
                    "slug": slug,
                    "name": p.name || slug,
                    "wallpaper": wall,
                    // folder the wallpaper picker opens; empty: the one of the current wallpaper
                    "wallpaperFolder": typeof p.wallpaperFolder === "string" ? p.wallpaperFolder : "",
                    // small preview for the picker; the full wallpaper takes
                    // noticeably longer to load (about 6 MB PNG per profile)
                    "thumb": hasThumb ? store.dir(slug) + "/thumb.jpg" : wall,
                    "created": p.created || "",
                    "updated": p.updated || "",
                    "active": slug === state.active,
                    "shown": !(Array.isArray(state.hidden) && state.hidden.indexOf(slug) >= 0),
                    "resettable": !same
                });
            }
            list.sort((a, b) => a.created < b.created ? -1 : (a.created > b.created ? 1 : 0));
            const saved = Array.isArray(state.order) ? state.order : [];
            const rank = s => {
                const r = saved.indexOf(s);
                return r < 0 ? saved.length : r;
            };
            list.sort((a, b) => rank(a.slug) - rank(b.slug));
            // an active slug whose folder is gone (deleted profile) is cleared,
            // so nothing keeps saving into a profile that no longer exists
            const active = state.active || "";
            store.activeSlug = list.some(p => p.slug === active) ? active : "";
            if (active && store.activeSlug !== active)
                store.writeJson(store.root + "/state.json", {
                    "active": "",
                    "order": list.map(p => p.slug),
                    "hidden": Array.isArray(state.hidden) ? state.hidden : []
                }, null);
            store.order = saved;
            store.hidden = (Array.isArray(state.hidden) ? state.hidden : []).filter(s => list.some(p => p.slug === s));
            store.profiles = list;
            store.loaded = true;
            store.changed();
            if (callback)
                callback(list);
        });
    }

    FileView {
        id: reader
        blockLoading: true
        printErrors: false
    }

    function readText(path) {
        reader.path = path;
        reader.reload();
        reader.waitForJob();
        return reader.text();
    }

    function load(slug) {
        try {
            return JSON.parse(store.readText(store.dir(slug) + "/profile.json"));
        } catch (e) {
            return null;
        }
    }

    // ------------------------------------------------------------------ wallpapers
    // The wallpaper the preview and the transition use. With a wallpaper per
    // monitor, wallpaperPath is often empty or stale; then the one of the
    // monitor the colors come from, else the first monitor.
    function mainWallpaper(session) {
        const s = session || {};
        const map = s.monitorWallpapers;
        if (s.perMonitorWallpaper === true && map && typeof map === "object") {
            const keys = [];
            if (SettingsData.matugenTargetMonitor)
                keys.push(SettingsData.matugenTargetMonitor);
            const screens = Quickshell.screens;
            if (screens.length > 0) {
                keys.push(screens[0].name);
                if (screens[0].model)
                    keys.push(screens[0].model);
            }
            for (const k of keys) {
                if (map[k] && !String(map[k]).startsWith("#"))
                    return map[k];
            }
            const rest = Object.keys(map).sort().map(k => map[k]).filter(v => v && !String(v).startsWith("#"));
            if (rest.length > 0)
                return rest[0];
        }
        return s.wallpaperPath || "";
    }

    // All image paths a profile uses besides the main wallpaper
    function otherWallpapers(session, main) {
        const s = session || {};
        const found = [];
        const add = v => {
            if (v && typeof v === "string" && !v.startsWith("#") && v !== main && found.indexOf(v) < 0)
                found.push(v);
        };
        for (const key of ["monitorWallpapers", "monitorWallpapersLight", "monitorWallpapersDark"]) {
            const map = s[key];
            if (map && typeof map === "object")
                Object.keys(map).sort().forEach(k => add(map[k]));
        }
        add(s.wallpaperPathLight);
        add(s.wallpaperPathDark);
        return found;
    }

    // Path of the saved copy of an original wallpaper path, else the path itself
    function resolveWallpaper(slug, profile, path) {
        const files = profile && profile.wallpaperFiles;
        if (path && files && files[path])
            return store.dir(slug) + "/" + files[path];
        return path;
    }

    function find(slug) {
        return store.profiles.find(p => p.slug === slug) || null;
    }

    // ------------------------------------------------------------------ writing
    function writeState(callback) {
        store.writeJson(store.root + "/state.json", {
            "active": store.activeSlug,
            "order": store.profiles.map(p => p.slug),
            "hidden": store.hidden
        }, callback);
    }

    // Show or hide a profile in the picker; it stays in Settings either way
    function setShown(slug, shown, callback) {
        const rest = store.hidden.filter(s => s !== slug);
        store.hidden = shown ? rest : rest.concat([slug]);
        store.writeState(() => store.refresh(callback));
    }

    function setActive(slug, callback) {
        store.activeSlug = slug;
        store.writeState(() => store.refresh(callback));
    }

    // Saves a snapshot into a profile. Copies the wallpaper only when it differs.
    function save(slug, name, snapshot, extras, callback) {
        const d = store.dir(slug);
        const old = store.load(slug) || {};
        const session = snapshot && snapshot.session ? snapshot.session : {};
        const wall = store.mainWallpaper(session);
        const dot = wall.lastIndexOf(".");
        const ext = dot > wall.lastIndexOf("/") ? wall.substring(dot) : ".png";
        const wallName = wall && !wall.startsWith("#") ? "wallpaper" + ext : (old.wallpaper || "");
        const now = Qt.formatDateTime(new Date(), "yyyy-MM-dd'T'HH:mm:ss");
        const profile = Object.assign({}, old, {
            "name": name,
            "created": old.created || now,
            "updated": now,
            "wallpaper": wallName,
            "dms": snapshot,
            "extras": extras === undefined ? (old.extras || null) : extras
        });
        delete profile.wallpaperFiles;
        let script = "mkdir -p " + store.quote(d);
        if (wall && !wall.startsWith("#")) {
            const target = d + "/" + wallName;
            script += " && { cmp -s " + store.quote(wall) + " " + store.quote(target) + " || { cp -f " + store.quote(wall) + " " + store.quote(target) + " && for f in " + store.quote(d) + "/wallpaper.*; do [ \"$f\" = " + store.quote(target) + " ] || rm -f \"$f\"; done; }; }";
        }
        // Further wallpapers as wallpaper-<n>.<ext>; prints the name of each
        // copy that exists afterwards, a missing original is left out
        const others = store.otherWallpapers(session, wall);
        const names = others.map((src, i) => {
            const dot = src.lastIndexOf(".");
            return "wallpaper-" + (i + 1) + (dot > src.lastIndexOf("/") ? src.substring(dot) : ".png");
        });
        script += "; ";
        others.forEach((src, i) => {
            const target = d + "/" + names[i];
            script += "{ cmp -s " + store.quote(src) + " " + store.quote(target) + " || cp -f " + store.quote(src) + " " + store.quote(target) + "; } 2>/dev/null; [ -f " + store.quote(target) + " ] && printf '%s\\n' " + store.quote(names[i]) + "; ";
        });
        script += "for f in " + store.quote(d) + "/wallpaper-*; do [ -e \"$f\" ] || continue; case \"${f##*/}\" in " + (names.length > 0 ? names.map(n => store.quote(n)).join("|") : "''") + ") ;; *) rm -f \"$f\" ;; esac; done; true";
        store.sh(script, out => {
            if (session.perMonitorWallpaper === true || session.perModeWallpaper === true) {
                const have = String(out).split("\n");
                const files = {};
                if (wall && !wall.startsWith("#") && wallName)
                    files[wall] = wallName;
                others.forEach((src, i) => {
                    if (have.indexOf(names[i]) >= 0)
                        files[src] = names[i];
                });
                profile.wallpaperFiles = files;
            }
            store.writeJson(d + "/profile.json", profile, () => store.refresh(callback));
        });
    }

    // Sets (or, with an empty path, clears) the wallpaper folder of a profile.
    // Also in .start/, or "undo changes" would bring the old folder back.
    function setWallpaperFolder(slug, path, callback) {
        const d = store.dir(slug);
        const patch = file => {
            let p;
            try {
                p = JSON.parse(store.readText(file));
            } catch (e) {
                return false;
            }
            if (path)
                p.wallpaperFolder = path;
            else
                delete p.wallpaperFolder;
            return p;
        };
        const p = patch(d + "/profile.json");
        if (!p) {
            callback && callback("failed");
            return;
        }
        const start = patch(d + "/.start/profile.json");
        store.writeJson(d + "/profile.json", p, () => {
            const done = () => store.refresh(() => callback && callback(""));
            if (start)
                store.writeJson(d + "/.start/profile.json", start, done);
            else
                done();
        });
    }

    function writeStart(slug, callback) {
        const d = store.dir(slug);
        store.sh("rm -rf " + store.quote(d + "/.start") + " && mkdir -p " + store.quote(d + "/.start") + " && cp -p " + store.quote(d) + "/profile.json " + store.quote(d) + "/wallpaper.* " + store.quote(d) + "/wallpaper-* " + store.quote(d + "/.start/") + " 2>/dev/null; true", () => store.refresh(callback));
    }

    function restoreStart(slug, callback) {
        const d = store.dir(slug);
        store.sh("[ -f " + store.quote(d + "/.start/profile.json") + " ] && rm -f " + store.quote(d) + "/wallpaper.* " + store.quote(d) + "/wallpaper-* && cp -p " + store.quote(d + "/.start") + "/* " + store.quote(d + "/"), (out, code) => store.refresh(() => callback && callback(code === 0)));
    }

    // Converts profile.json (and .start/profile.json) with convert(dms), which
    // returns the dms part unchanged when there is nothing to do. The original
    // is kept as profile.v<old version>.json. Calls back with true if converted.
    function migrate(slug, convert, callback) {
        const d = store.dir(slug);
        const text = store.readText(d + "/profile.json");
        let p = null;
        try {
            p = JSON.parse(text);
        } catch (e) {}
        if (!p || !p.dms) {
            callback(false);
            return;
        }
        const from = Migration.profileVersion(p.dms, SettingsData.settingsConfigVersion || 0);
        const dms = convert(p.dms);
        if (dms === p.dms) {
            callback(false);
            return;
        }
        const out = Object.assign({}, p, {
            "dms": dms
        });
        // The start copy is usually the same file; then it gets the same result,
        // so the profile does not show up as changed
        const startText = store.readText(d + "/.start/profile.json");
        let start = null;
        if (startText === text) {
            start = out;
        } else if (startText) {
            try {
                const s = JSON.parse(startText);
                if (s && s.dms)
                    start = Object.assign({}, s, {
                        "dms": convert(s.dms)
                    });
            } catch (e) {}
        }
        const backup = d + "/profile.v" + from + ".json";
        store.sh("[ -e " + store.quote(backup) + " ] || cp -p " + store.quote(d + "/profile.json") + " " + store.quote(backup), (o, code) => {
            if (code !== 0) {
                console.warn("Profiles: no backup of", slug, "- left unconverted");
                callback(false);
                return;
            }
            store.writeJson(d + "/profile.json", out, () => {
                if (start)
                    store.writeJson(d + "/.start/profile.json", start, () => callback(true));
                else
                    callback(true);
            });
        });
    }

    function rename(slug, newName, callback) {
        const name = String(newName).trim();
        const target = store.slugify(name);
        if (!name || !target) {
            callback && callback("empty");
            return;
        }
        if (target !== slug && store.find(target)) {
            callback && callback("exists");
            return;
        }
        const move = target === slug ? "true" : "mv " + store.quote(store.dir(slug)) + " " + store.quote(store.dir(target));
        store.sh(move, (out, code) => {
            if (code !== 0) {
                callback && callback("failed");
                return;
            }
            const p = store.load(target) || {};
            p.name = name;
            store.writeJson(store.dir(target) + "/profile.json", p, () => {
                const start = store.dir(target) + "/.start/profile.json";
                store.sh("[ -f " + store.quote(start) + " ]", (o, c) => {
                    // state first, then read back: a refresh would take the old
                    // slug from state.json and write it again
                    const finish = () => {
                        if (store.activeSlug === slug)
                            store.activeSlug = target;
                        const order = store.profiles.map(p => p.slug === slug ? target : p.slug);
                        store.writeJson(store.root + "/state.json", {
                            "active": store.activeSlug,
                            "order": order
                        }, () => store.refresh(() => callback && callback("")));
                    };
                    if (c !== 0) {
                        finish();
                        return;
                    }
                    reader.path = start;
                    reader.reload();
                    reader.waitForJob();
                    let s = {};
                    try {
                        s = JSON.parse(reader.text());
                    } catch (e) {}
                    s.name = name;
                    store.writeJson(start, s, finish);
                });
            });
        });
    }

    function remove(slug, callback) {
        if (!slug || slug.indexOf("/") >= 0 || slug.startsWith(".")) {
            callback && callback(false);
            return;
        }
        store.sh("rm -rf -- " + store.quote(store.dir(slug)), (out, code) => {
            if (store.activeSlug === slug)
                store.activeSlug = "";
            const order = store.profiles.map(p => p.slug).filter(s => s !== slug);
            store.writeJson(store.root + "/state.json", {
                "active": store.activeSlug,
                "order": order
            }, () => store.refresh(() => callback && callback(code === 0)));
        });
    }

    // where: "left" | "right" | 1-based position
    function move(slug, where, callback) {
        const slugs = store.profiles.map(p => p.slug);
        const i = slugs.indexOf(slug);
        if (i < 0) {
            callback && callback(false);
            return;
        }
        let j = i;
        if (where === "left" || where === "up")
            j = Math.max(0, i - 1);
        else if (where === "right" || where === "down")
            j = Math.min(slugs.length - 1, i + 1);
        else if (!isNaN(parseInt(where)))
            j = Math.max(0, Math.min(slugs.length - 1, parseInt(where) - 1));
        slugs.splice(j, 0, slugs.splice(i, 1)[0]);
        store.writeJson(store.root + "/state.json", {
            "active": store.activeSlug,
            "order": slugs
        }, () => store.refresh(() => callback && callback(true)));
    }
}

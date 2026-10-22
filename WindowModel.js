.pragma library

function ipcFor(toplevel) {
    var ipc = toplevel && toplevel.lastIpcObject;
    return ipc && typeof ipc === "object" ? ipc : {};
}

function waylandFor(toplevel) {
    return toplevel && toplevel.wayland ? toplevel.wayland : null;
}

function appIdFor(toplevel) {
    var wayland = waylandFor(toplevel);
    if (wayland && wayland.appId)
        return String(wayland.appId);
    var ipc = ipcFor(toplevel);
    return String(ipc.class || ipc.initialClass || "");
}

// The window's application as a person would name it: the last dotted part
// of its id, "-" when it has none.
function appNameFor(toplevel) {
    var parts = appIdFor(toplevel).split(".").filter(function (part) { return part.length > 0; });
    return parts.length ? parts[parts.length - 1] : "-";
}

function addressFor(toplevel) {
    var address = String((toplevel && toplevel.address) || "");
    return /^[0-9a-fA-F]+$/.test(address) ? "0x" + address : "";
}

function isEligible(toplevel) {
    return Boolean(waylandFor(toplevel)) && ipcFor(toplevel).mapped !== false;
}

function workspaceName(toplevel) {
    var workspace = toplevel && toplevel.workspace ? toplevel.workspace : null;
    return workspace ? String(workspace.name || workspace.id || "—") : "—";
}

// Workspace names are free-form in Hyprland. Plugins that give every monitor its
// own set name them "<monitor description>:<slot>", which is far too wide for a
// card footer, so "slot" keeps the trailing slot number. Anything else, including
// "special:scratchpad", is returned unchanged.
function formatWorkspaceLabel(name, style) {
    var text = String(name === null || name === undefined ? "" : name);
    if (style !== "slot" || text.indexOf("special:") === 0)
        return text;
    var match = text.match(/^.+:(\d+)$/);
    return match ? match[1] : text;
}

function isOnScreen(toplevel, screenName, perMonitor) {
    if (!perMonitor)
        return true;
    var monitor = toplevel && toplevel.monitor ? toplevel.monitor : null;
    return Boolean(monitor) && String(monitor.name || "") === String(screenName || "");
}

function isOnWorkspace(toplevel, workspace) {
    var toplevelWorkspace = toplevel && toplevel.workspace ? toplevel.workspace : null;
    if (!toplevelWorkspace || !workspace)
        return false;
    if (ipcFor(toplevel).pinned === true || toplevelWorkspace === workspace)
        return true;

    var toplevelId = Number(toplevelWorkspace.id);
    var workspaceId = Number(workspace.id);
    if (isFinite(toplevelId) && isFinite(workspaceId) && toplevelId !== 0 && workspaceId !== 0)
        return toplevelId === workspaceId;

    var workspaceName = String(workspace.name || "");
    return Boolean(workspaceName) && String(toplevelWorkspace.name || "") === workspaceName;
}

function aspectRatioFor(toplevel) {
    var size = ipcFor(toplevel).size || [];
    var width = Number(size[0]);
    var height = Number(size[1]);
    if (size.length < 2 || !isFinite(width) || !isFinite(height) || width <= 0 || height <= 0)
        return 1.6;
    return Math.max(0.45, Math.min(4, width / height));
}

// Where the window sits in compositor (logical) coordinates; null when unknown.
function frameFor(toplevel) {
    var ipc = ipcFor(toplevel);
    var at = ipc.at || [];
    var size = ipc.size || [];
    var x = Number(at[0]), y = Number(at[1]), width = Number(size[0]), height = Number(size[1]);
    if (at.length < 2 || size.length < 2 || ![x, y, width, height].every(isFinite) || width <= 0 || height <= 0)
        return null;
    return { x: x, y: y, width: width, height: height };
}

// The logical rect of the window's monitor: pixels divided by its scale, with
// width and height swapped when it is rotated a quarter turn. Null when unknown.
function viewportFor(toplevel) {
    var monitor = toplevel && toplevel.monitor ? toplevel.monitor : null;
    if (!monitor)
        return null;
    var scale = Number(monitor.scale) > 0 ? Number(monitor.scale) : 1;
    var width = Number(monitor.width) / scale, height = Number(monitor.height) / scale;
    var transform = Number((monitor.lastIpcObject || {}).transform) || 0;
    var x = Number(monitor.x) || 0, y = Number(monitor.y) || 0;
    if (!(width > 0 && height > 0))
        return null;
    return transform % 2 === 1
        ? { x: x, y: y, width: height, height: width }
        : { x: x, y: y, width: width, height: height };
}

// The window's place in Hyprland's focus history, 0 for the most recently
// focused; -1 when unknown.
function focusHistoryFor(toplevel) {
    var id = ipcFor(toplevel).focusHistoryID;
    return typeof id === "number" && id >= 0 ? id : -1;
}

// The window Hyprland focused last, by focus history; null when none is known.
function mostRecent(toplevels) {
    return toplevels.find(function (toplevel) { return focusHistoryFor(toplevel) === 0; }) || null;
}

function searchTextFor(toplevel) {
    var ipc = ipcFor(toplevel);
    return (appIdFor(toplevel) + " " + String(ipc.class || "") + " "
        + String(ipc.initialClass || "") + " " + String((toplevel && toplevel.title) || "")).toLowerCase();
}

// What Enter opens: the chosen window while it is listed, else the window the
// overview was opened from, else the first listed window.
function selectionFor(listed, selected, origin) {
    if (selected && listed.indexOf(selected) !== -1)
        return selected;
    if (origin && listed.indexOf(origin) !== -1)
        return origin;
    return listed.length ? listed[0] : null;
}

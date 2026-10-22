.pragma library
.import "WindowModel.js" as WindowModel

// Windows grouped by workspace, for looks that draw each workspace as a plane
// with every window at its real place on it, so a scrolling layout's
// off-screen windows appear beside the monitor's viewport.

// The listed windows grouped by workspace: planes in stacking order (each with
// its id, name, viewport, frames, and extent), each window's plane index and
// frame, and navigation rects. A window with no known frame fills its
// workspace's viewport; a workspace with no known monitor uses
// `fallbackViewport`. Toplevels are read through WindowModel.
function snapshot(toplevels, fallbackViewport) {
    var byKey = {};
    var workspaces = [];
    var keys = toplevels.map(function (top) {
        var workspace = top.workspace;
        var key = workspace ? String(workspace.id) + "/" + String(workspace.name) : "-";
        if (!byKey[key]) {
            byKey[key] = {
                id: workspace ? Number(workspace.id) : 0,
                name: WindowModel.workspaceName(top),
                viewport: WindowModel.viewportFor(top) || fallbackViewport,
                frames: []
            };
            workspaces.push(byKey[key]);
        }
        return key;
    });
    var frames = toplevels.map(function (top, index) {
        var frame = WindowModel.frameFor(top) || byKey[keys[index]].viewport;
        byKey[keys[index]].frames.push(frame);
        return frame;
    });
    var planes = planeOrder(workspaces);
    planes.forEach(function (plane) { plane.extent = extent(plane.viewport, plane.frames); });
    var planeOf = keys.map(function (key) { return planes.indexOf(byKey[key]); });
    return {
        toplevels: toplevels,
        planes: planes,
        planeOf: planeOf,
        frames: frames,
        nav: navRects(frames.map(function (frame, index) {
            return { plane: planeOf[index], rect: frame, extent: planes[planeOf[index]].extent };
        }))
    };
}

// The box a workspace occupies: its monitor's viewport and every window on it.
function extent(viewport, windows) {
    var left = viewport.x, top = viewport.y;
    var right = viewport.x + viewport.width, bottom = viewport.y + viewport.height;
    windows.forEach(function (rect) {
        left = Math.min(left, rect.x);
        top = Math.min(top, rect.y);
        right = Math.max(right, rect.x + rect.width);
        bottom = Math.max(bottom, rect.y + rect.height);
    });
    return { x: left, y: top, width: right - left, height: bottom - top };
}

// The largest plane with the extent's shape inside maxWidth x maxHeight.
function fitPlane(box, maxWidth, maxHeight) {
    var ratio = box.width > 0 && box.height > 0 ? box.width / box.height : 16 / 9;
    var width = Math.min(maxWidth, maxHeight * ratio);
    return { width: width, height: width / ratio };
}

// A rect in compositor coordinates, scaled onto a plane of the given size.
function onPlane(rect, box, plane) {
    var sx = box.width > 0 ? plane.width / box.width : 0;
    var sy = box.height > 0 ? plane.height / box.height : 0;
    return {
        x: (rect.x - box.x) * sx,
        y: (rect.y - box.y) * sy,
        width: rect.width * sx,
        height: rect.height * sy
    };
}

// Workspaces in stacking order: numbered ones ascending, named and special
// ones (id <= 0) after them in name order.
function planeOrder(workspaces) {
    return workspaces.slice().sort(function (a, b) {
        var aNumbered = a.id > 0, bNumbered = b.id > 0;
        if (aNumbered !== bNumbered)
            return aNumbered ? -1 : 1;
        if (aNumbered)
            return a.id - b.id;
        return String(a.name) < String(b.name) ? -1 : (String(a.name) > String(b.name) ? 1 : 0);
    });
}

// Rects for directional navigation, one per window: each plane is a band of
// its own, so Left/Right stay on a plane and Up/Down reach a window above or
// below on the same plane before the next plane. `entries` holds each
// window's plane index, rect, and its plane's extent.
function navRects(entries) {
    return entries.map(function (entry) {
        var box = entry.extent;
        var scale = 1000 / Math.max(box.height, 1);
        return {
            x: (entry.rect.x - box.x) * scale,
            y: entry.plane * 2000 + (entry.rect.y - box.y) * scale,
            width: entry.rect.width * scale,
            height: entry.rect.height * scale
        };
    });
}

.pragma library

// Workspace strata geometry. Every workspace is a glass plane laid back in
// perspective; planes stack vertically and the camera follows the plane that
// holds the selection. A window keeps its real place on its plane, so a
// scrolling layout's off-screen windows appear beside the monitor's viewport.

var frontAngle = 28;     // degrees the selection's plane is laid back
var backAngle = 62;      // ...and every other plane
var reach = 2.5;         // planes beyond this offset fade out and stop capturing
var centreYFraction = 0.4; // where the front plane's centre sits, as a fraction of the height

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

// Where the plane at `offset` from the camera sits: the y of its centre, how
// far it is laid back, its scale, stacking order, shade, and opacity. The
// stack spaces planes by the front plane's laid-back height.
function placePlane(offset, areaHeight, planeHeight) {
    var distance = Math.abs(offset);
    var near = Math.min(distance, 1);
    var step = planeHeight * Math.cos(backAngle * Math.PI / 180) * 0.75 + areaHeight * 0.05;
    var frontGap = planeHeight * 0.22;
    var side = offset < 0 ? -1 : 1;
    return {
        centreY: areaHeight * centreYFraction + side * (near * frontGap + distance * step),
        angle: frontAngle + (backAngle - frontAngle) * near,
        scale: 1 - 0.12 * Math.min(distance, 2),
        z: Math.round((reach + 1 - Math.min(distance, reach + 1)) * 100),
        shade: 0.45 * near,
        opacity: Math.max(0, Math.min(1, reach + 1 - distance))
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

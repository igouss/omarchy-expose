.pragma library

// Diorama geometry: the desktop as a small model seen from above at an angle.
// World coordinates are compositor pixels: u runs along a workspace's x, v
// along its y, and h up off the floor. Workspaces lie as slabs in a grid;
// windows stand on them as blocks at their real places.

var yaw = 32;              // degrees the model is turned
var squash = 0.58;         // how flat the floor is drawn (1 = straight down)
var slabThickness = 90;    // world pixels
var blockHeight = 60;
var liftHeight = 240;      // the selection's block rises this far
var gapFraction = 0.14;    // space between slabs, as a share of the largest one

var radians = yaw * Math.PI / 180;

// A world point on screen before scaling: u runs right and down, v left and
// down, h straight up.
function project(u, v, h) {
    return {
        x: u * Math.cos(radians) - v * Math.sin(radians),
        y: (u * Math.sin(radians) + v * Math.cos(radians)) * squash - h
    };
}

// Where each slab's corner lies on the floor: a grid of ceil(sqrt(n)) columns,
// every cell the size of the largest extent plus a gap.
function arrange(extents) {
    var columns = Math.max(1, Math.ceil(Math.sqrt(extents.length)));
    var cellWidth = 0, cellDepth = 0;
    extents.forEach(function (box) {
        cellWidth = Math.max(cellWidth, box.width);
        cellDepth = Math.max(cellDepth, box.height);
    });
    var gap = Math.max(cellWidth, cellDepth) * gapFraction;
    return extents.map(function (box, index) {
        return { u: (index % columns) * (cellWidth + gap), v: Math.floor(index / columns) * (cellDepth + gap) };
    });
}

// A rect in compositor coordinates on the slab whose extent is `box` and whose
// corner lies at `origin`, as a floor rect { u, v, width, depth }.
function onFloor(rect, box, origin) {
    return { u: origin.u + rect.x - box.x, v: origin.v + rect.y - box.y, width: rect.width, depth: rect.height };
}

// The four projected corners of a floor rect lifted to height h: the far
// corner, along u, along v, and the near corner.
function corners(floor, h) {
    return [
        project(floor.u, floor.v, h),
        project(floor.u + floor.width, floor.v, h),
        project(floor.u, floor.v + floor.depth, h),
        project(floor.u + floor.width, floor.v + floor.depth, h)
    ];
}

// The box around projected points; zero size when there are none.
function bounds(points) {
    if (!points.length)
        return { x: 0, y: 0, width: 0, height: 0 };
    var left = Infinity, top = Infinity, right = -Infinity, bottom = -Infinity;
    points.forEach(function (point) {
        left = Math.min(left, point.x);
        top = Math.min(top, point.y);
        right = Math.max(right, point.x);
        bottom = Math.max(bottom, point.y);
    });
    return { x: left, y: top, width: right - left, height: bottom - top };
}

// The scale and offset that fit `box` centred inside the area.
function fit(box, areaWidth, areaHeight) {
    var scale = box.width > 0 && box.height > 0 ? Math.min(areaWidth / box.width, areaHeight / box.height) : 1;
    return {
        scale: scale,
        x: (areaWidth - box.width * scale) / 2 - box.x * scale,
        y: (areaHeight - box.height * scale) / 2 - box.y * scale
    };
}

// A projected point placed in the area by a fitted view.
function toScreen(point, view) {
    return { x: view.x + point.x * view.scale, y: view.y + point.y * view.scale };
}

// The 4x4 matrix (row-major, for Qt.matrix4x4) that maps an item of the given
// size onto the parallelogram with corner p0, its x edge ending at px and its
// y edge at py.
function faceMatrix(p0, px, py, width, height) {
    var w = Math.max(width, 1e-6), h = Math.max(height, 1e-6);
    return [
        (px.x - p0.x) / w, (py.x - p0.x) / h, 0, p0.x,
        (px.y - p0.y) / w, (py.y - p0.y) / h, 0, p0.y,
        0, 0, 1, 0,
        0, 0, 0, 1
    ];
}

// Painter's order for a floor rect: nearer (further down the screen) is larger.
function depthOf(floor) {
    return project(floor.u + floor.width / 2, floor.v + floor.depth / 2, 0).y;
}

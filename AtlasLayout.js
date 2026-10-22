.pragma library

// Atlas geometry: the whole desktop as one map in compositor pixels.
// Workspaces lie side by side in a row, each window at its real place; a
// camera (centre and zoom) decides what part of the map fills the screen.

var gapFraction = 0.08;   // space between workspaces, as a share of the tallest one
var margin = 0.12;        // room left around a framed rect, as a share of its size
var minZoom = 1e-4;

// Where each workspace's corner lies on the map: left to right in order,
// tops aligned, a gap between neighbours.
function arrange(extents) {
    var tallest = 0;
    extents.forEach(function (box) { tallest = Math.max(tallest, box.height); });
    var gap = tallest * gapFraction;
    var x = 0;
    return extents.map(function (box) {
        var place = { x: x, y: 0 };
        x += box.width + gap;
        return place;
    });
}

// A rect in compositor coordinates on the workspace whose extent is `box` and
// whose corner lies at `origin`, on the map.
function onMap(rect, box, origin) {
    return { x: origin.x + rect.x - box.x, y: origin.y + rect.y - box.y, width: rect.width, height: rect.height };
}

// The smallest rect holding every rect given; null for none.
function union(rects) {
    if (!rects.length)
        return null;
    var left = Infinity, top = Infinity, right = -Infinity, bottom = -Infinity;
    rects.forEach(function (rect) {
        left = Math.min(left, rect.x);
        top = Math.min(top, rect.y);
        right = Math.max(right, rect.x + rect.width);
        bottom = Math.max(bottom, rect.y + rect.height);
    });
    return { x: left, y: top, width: right - left, height: bottom - top };
}

// The camera that shows all of `rect`, centred, with the margin around it,
// zoomed in no further than `maxZoom` when one is given. An area not laid out
// yet still gets a positive zoom, so nothing divided by it turns NaN.
function frame(rect, areaWidth, areaHeight, maxZoom) {
    var width = Math.max(rect.width, 1) * (1 + 2 * margin);
    var height = Math.max(rect.height, 1) * (1 + 2 * margin);
    return {
        x: rect.x + rect.width / 2,
        y: rect.y + rect.height / 2,
        zoom: Math.max(minZoom, Math.min(areaWidth / width, areaHeight / height, maxZoom === undefined ? Infinity : maxZoom))
    };
}

// A map rect on screen under the camera.
function toScreen(rect, camera, areaWidth, areaHeight) {
    return {
        x: areaWidth / 2 + (rect.x - camera.x) * camera.zoom,
        y: areaHeight / 2 + (rect.y - camera.y) * camera.zoom,
        width: rect.width * camera.zoom,
        height: rect.height * camera.zoom
    };
}

// Whether a screen rect overlaps the area.
function onScreen(rect, areaWidth, areaHeight) {
    return rect.x < areaWidth && rect.y < areaHeight && rect.x + rect.width > 0 && rect.y + rect.height > 0;
}

// The smallest map distance of the form 1, 2, or 5 times a power of ten that
// is at least `least`.
function niceStep(least) {
    var power = Math.pow(10, Math.floor(Math.log(Math.max(least, 1e-9)) / Math.LN10));
    var steps = [1, 2, 5];
    for (var index = 0; index < steps.length; index++) {
        if (steps[index] * power >= least)
            return steps[index] * power;
    }
    return 10 * power;
}

// Graticule lines on screen: map multiples of a nice step at least
// `minPixels` apart, as screen x positions and screen y positions; at most
// `maxLines` each way, so a degenerate camera never loops long.
var maxLines = 200;

function gridLines(camera, areaWidth, areaHeight, minPixels) {
    var step = niceStep(minPixels / camera.zoom);
    function along(centre, size) {
        var first = Math.ceil((centre - size / 2 / camera.zoom) / step) * step;
        var lines = [];
        for (var index = 0; index < maxLines; index++) {
            var at = (first + index * step - centre) * camera.zoom + size / 2;
            if (!(at <= size))
                break;
            lines.push(at);
        }
        return lines;
    }
    return { step: step, xs: along(camera.x, areaWidth), ys: along(camera.y, areaHeight) };
}

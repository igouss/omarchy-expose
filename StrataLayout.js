.pragma library

// Workspace strata geometry. Every workspace is a glass plane laid back in
// perspective; planes stack vertically and the camera follows the plane that
// holds the selection. Planes and the windows on them come from
// WorkspacePlanes.js.

var frontAngle = 28;     // degrees the selection's plane is laid back
var backAngle = 62;      // ...and every other plane
var reach = 2.5;         // planes beyond this offset fade out and stop capturing
var centreYFraction = 0.4; // where the front plane's centre sits, as a fraction of the height

// Where the plane at `offset` from the camera sits: the y of its centre, how
// far it is laid back, its turn (none: strata face the viewer), its scale,
// stacking order, shade, and opacity. The stack spaces planes by the front
// plane's laid-back height.
function placePlane(offset, areaHeight, planeHeight) {
    var distance = Math.abs(offset);
    var near = Math.min(distance, 1);
    var step = planeHeight * Math.cos(backAngle * Math.PI / 180) * 0.75 + areaHeight * 0.05;
    var frontGap = planeHeight * 0.22;
    var side = offset < 0 ? -1 : 1;
    return {
        centreY: areaHeight * centreYFraction + side * (near * frontGap + distance * step),
        angle: frontAngle + (backAngle - frontAngle) * near,
        turn: 0,
        scale: 1 - 0.12 * Math.min(distance, 2),
        z: Math.round((reach + 1 - Math.min(distance, reach + 1)) * 100),
        shade: 0.45 * near,
        opacity: Math.max(0, Math.min(1, reach + 1 - distance))
    };
}

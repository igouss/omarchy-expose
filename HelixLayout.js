.pragma library

// Helix geometry: workspace floors wound around a vertical spine like a
// spiral staircase. A floor's place depends only on its offset from the
// camera's (fractional) floor: each step turns it a fixed angle around the
// spine and drops it one pitch, so the camera turns the tower to bring the
// selection's floor to the front.

var stepAngle = 52;          // degrees each floor turns around the spine
var layBack = 24;            // degrees every floor is laid back
var radiusFraction = 0.2;    // the spine's radius, as a fraction of the width
var focalFactor = 2.6;       // perspective distance, in radii
var pitchFactor = 0.85;      // drop per floor, as a share of the plane height
var reach = 2;               // floors beyond this offset fade out and stop capturing
var centreYFraction = 0.4;   // the front floor's centre, as a fraction of the height

// Where the floor at `offset` sits: its centre, how far it is laid back and
// turned to face out from the spine, its scale, stacking order (nearer is
// higher), shade, and opacity.
function placeFloor(offset, areaWidth, areaHeight, planeHeight) {
    var theta = offset * stepAngle * Math.PI / 180;
    var radius = areaWidth * radiusFraction;
    var depth = radius * (1 - Math.cos(theta));
    var scale = focalFactor / (focalFactor + depth / Math.max(radius, 1e-6));
    var distance = Math.abs(offset);
    return {
        centreX: areaWidth / 2 + radius * Math.sin(theta) * scale,
        centreY: areaHeight * centreYFraction + offset * planeHeight * pitchFactor * scale,
        angle: layBack,
        turn: offset * stepAngle,
        scale: scale,
        depth: depth,
        z: -Math.round(depth),
        shade: 0.6 * (1 - Math.cos(theta)) / 2,
        opacity: Math.max(0, Math.min(1, reach + 1 - distance))
    };
}

// The spine's stacking order: in front of floors turned past a quarter turn,
// behind the rest.
function spineZ(areaWidth) {
    return -Math.round(areaWidth * radiusFraction);
}

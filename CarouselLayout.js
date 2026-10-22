.pragma library

// Cover-flow geometry. A card's place depends only on its offset from the
// centre (selected) card, a real number while the carousel animates: 0 is the
// front-centre card, ±1 the first card turned away on either side, and every
// further card stacks a short step outwards. Centres increase strictly with
// the offset on one horizontal line, so directional navigation picks i±1.

var sideAngle = 58;      // degrees a side card is turned away from the viewer
var sideScale = 0.74;
var reach = 4;           // cards beyond this offset fade out and stop capturing

// Box every card fits into, as fractions of the area.
var boxHeightFraction = 0.54;
var boxWidthFraction = 0.5;
var centreYFraction = 0.42;

// The largest size with the window's aspect ratio inside the box.
function fit(ratio, boxWidth, boxHeight) {
    var safe = ratio > 0 ? ratio : 16 / 9;
    var width = Math.min(boxWidth, boxHeight * safe);
    return { width: width, height: width / safe };
}

// Where the card at `offset` sits in an area of the given size: its unrotated
// rect, the turn (positive faces right, so left cards face the centre), its
// scale, stacking order, how much it is shaded, and whether it is visible.
function place(offset, ratio, areaWidth, areaHeight) {
    var boxHeight = areaHeight * boxHeightFraction;
    var size = fit(ratio, areaWidth * boxWidthFraction, boxHeight);
    var distance = Math.abs(offset);
    var side = offset < 0 ? -1 : 1;
    var turn = Math.min(distance, 1);
    var centreGap = boxHeight * 0.64;
    var step = boxHeight * 0.2;
    var centreX = areaWidth / 2 + side * (turn * centreGap + Math.max(0, distance - 1) * step);
    var centreY = areaHeight * centreYFraction;
    return {
        x: centreX - size.width / 2,
        y: centreY - size.height / 2,
        width: size.width,
        height: size.height,
        angle: -side * sideAngle * turn,
        scale: 1 - (1 - sideScale) * turn,
        z: Math.round((reach + 1 - Math.min(distance, reach + 1)) * 100),
        shade: 0.5 * turn,
        opacity: Math.max(0, Math.min(1, reach + 1 - distance))
    };
}

// One rect per window for directional navigation, with `selected` at the centre.
function layout(ratios, selected, areaWidth, areaHeight) {
    if (areaWidth <= 0 || areaHeight <= 0)
        return [];
    var centre = selected >= 0 ? selected : 0;
    return ratios.map(function (ratio, index) {
        var placed = place(index - centre, ratio, areaWidth, areaHeight);
        return { x: placed.x, y: placed.y, width: placed.width, height: placed.height };
    });
}

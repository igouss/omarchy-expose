.pragma library

// Time Machine geometry. Windows recede down a tunnel by recency: rank 0 is
// the most recently focused window. A card's place depends only on its depth,
// rank minus the camera's (fractional) position: 0 in front, positive further
// back toward a vanishing point above the centre, negative flying past the
// viewer.

var reach = 6;              // cards deeper than this fade out and stop capturing
var depthStep = 0.38;       // how fast cards shrink with depth
var vanishYFraction = 0.04; // the vanishing point's height, as a fraction of the area
var frontYFraction = 0.55;  // where the front card's centre sits
var boxWidthFraction = 0.6; // box the front card fits into
var boxHeightFraction = 0.6;

// Each window's rank from its focus history id: lower ids rank first; windows
// with no id (negative) follow in list order.
function ranks(historyIds) {
    var order = historyIds.map(function (id, index) { return index; });
    order.sort(function (a, b) {
        var aKnown = historyIds[a] >= 0, bKnown = historyIds[b] >= 0;
        if (aKnown !== bKnown)
            return aKnown ? -1 : 1;
        if (aKnown && historyIds[a] !== historyIds[b])
            return historyIds[a] - historyIds[b];
        return a - b;
    });
    var result = [];
    order.forEach(function (index, rank) { result[index] = rank; });
    return result;
}

// The largest size with the window's aspect ratio inside the box.
function fit(ratio, boxWidth, boxHeight) {
    var safe = ratio > 0 ? ratio : 16 / 9;
    var width = Math.min(boxWidth, boxHeight * safe);
    return { width: width, height: width / safe };
}

// How large a card at `depth` is drawn: 1 in front, shrinking with depth,
// growing as it flies past the viewer.
function scaleAt(depth) {
    return depth >= 0 ? 1 / (1 + depthStep * depth) : 1 - depth * 0.6;
}

// Where the card at `depth` sits: its unscaled rect (scale it about its centre),
// the scale, stacking order (nearer is higher), shade, and opacity. Centres
// slide up toward the vanishing point as cards shrink; cards fade beyond the
// reach and as they fly past.
function place(depth, ratio, areaWidth, areaHeight) {
    var size = fit(ratio, areaWidth * boxWidthFraction, areaHeight * boxHeightFraction);
    var scale = scaleAt(depth);
    var vanishY = areaHeight * vanishYFraction;
    var centreY = vanishY + (areaHeight * frontYFraction - vanishY) * scale;
    return {
        x: (areaWidth - size.width) / 2,
        y: centreY - size.height / 2,
        width: size.width,
        height: size.height,
        scale: scale,
        z: -Math.round(depth * 100),
        shade: Math.min(0.6, Math.max(0, depth) * 0.12),
        opacity: Math.max(0, Math.min(1, reach + 1 - depth, 1 + depth * 2))
    };
}

// One rect per window for directional navigation: a column by rank, older
// windows above, so Up steps back in time and Down forward.
function navRects(windowRanks) {
    return windowRanks.map(function (rank) {
        return { x: 0, y: -rank * 100, width: 100, height: 100 };
    });
}

// A star of the backdrop: a fixed pseudo-random spot in a tunnel `span` ranks
// long that wraps as the camera travels. Returns its place and how bright and
// large it is; stars brighten and grow as they near the viewer.
function star(index, travel, span, areaWidth, areaHeight) {
    var seed = Math.sin(index * 12.9898 + 78.233) * 43758.5453;
    var u = seed - Math.floor(seed);
    var seed2 = Math.sin(index * 39.3468 + 11.135) * 24634.6345;
    var v = seed2 - Math.floor(seed2);
    var lane = ((index * 0.618034 + 0.5 * u) % 1) * span;
    var depth = ((lane - travel) % span + span) % span;
    var scale = scaleAt(depth);
    var spreadX = (u - 0.5) * areaWidth * 1.6, spreadY = (v - 0.5) * areaHeight * 1.4;
    return {
        x: areaWidth / 2 + spreadX * scale,
        y: areaHeight * vanishYFraction + (spreadY + areaHeight * 0.3) * scale,
        depth: depth,
        size: 1 + 3 * scale,
        opacity: Math.min(1, scale * 1.4) * Math.min(1, (span - depth) * 2, depth * 1.5)
    };
}

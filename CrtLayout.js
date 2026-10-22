.pragma library

// CRT terminal geometry: a list of windows, one row each, beside a monitor
// showing the selection. Rows keep their place for directional navigation;
// the list scrolls so the selection stays in view.

var listFraction = 0.42;   // share of the width the list takes
var typeSpan = 0.5;        // share of the boot each row spends typing

// The list and monitor panes in an area, with a gap between them.
function panes(width, height, gap) {
    var listWidth = Math.max(0, Math.round(width * listFraction - gap / 2));
    return {
        list: { x: 0, y: 0, width: listWidth, height: height },
        monitor: { x: listWidth + gap, y: 0, width: Math.max(0, width - listWidth - gap), height: height }
    };
}

// One rect per row, unscrolled: arrows move between neighbouring rows.
function rowRects(count, rowHeight, width) {
    var rects = [];
    for (var index = 0; index < count; index++)
        rects.push({ x: 0, y: index * rowHeight, width: width, height: rowHeight });
    return rects;
}

// The scroll offset that keeps the selected row, and one row either side of
// it where there is one, in view while moving as little as possible from
// `current`. Never scrolls past either end of the list; a view with no
// height (not laid out yet) keeps the offset.
function listOffset(selected, count, rowHeight, viewHeight, current) {
    var maxOffset = Math.max(0, count * rowHeight - viewHeight);
    if (selected < 0 || count === 0 || viewHeight <= 0)
        return Math.min(Math.max(0, current), maxOffset);
    var context = viewHeight >= rowHeight * 3 ? rowHeight : 0;
    var top = selected * rowHeight - context;
    var bottom = (selected + 1) * rowHeight + context;
    var offset = current;
    if (top < offset)
        offset = top;
    else if (bottom > offset + viewHeight)
        offset = bottom - viewHeight;
    return Math.min(Math.max(0, offset), maxOffset);
}

// How much of row `index` of `count` has typed in while the boot runs 0 to 1:
// rows start one after another and each types for `typeSpan` of the boot.
function typed(index, count, boot) {
    var start = count > 1 ? index / (count - 1) * (1 - typeSpan) : 0;
    return Math.min(1, Math.max(0, (boot - start) / typeSpan));
}

// `text` cut to `width` characters, ending in an ellipsis when cut, then
// padded with spaces to exactly `width`.
function column(text, width) {
    var value = String(text);
    if (value.length > width)
        value = width > 1 ? value.slice(0, width - 1) + "…" : value.slice(0, width);
    while (value.length < width)
        value += " ";
    return value;
}

// One list row in fixed-width columns: number, workspace, application, title.
function row(number, workspace, app, title) {
    return column(String(number).padStart(2, "0"), 3) + column("ws:" + workspace, 7) + column(app, 12) + " " + title;
}

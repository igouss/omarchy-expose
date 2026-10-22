import QtQuick
import qs.Commons as Commons
import qs.Ui as Ui

// Use the shell's state palette and complete border specs, including gradients
// and per-side widths. A theme's zero width/alpha is intentional.
Ui.BorderSurface {
    id: root
    property bool focused: false
    property bool hovered: false
    property bool selected: false
    property bool pressed: false
    readonly property string controlState: focused ? "focus"
        : hovered ? "hover-cursor" : selected ? "selected" : "normal"
    readonly property color stateColor: focused ? Commons.Style.focusStateColor(Commons.Color.menu.text, Commons.Color.accent)
        : hovered ? Commons.Style.hoverStateColor(Commons.Color.menu.text, Commons.Color.accent)
        : selected ? Commons.Style.selectedStateColor(Commons.Color.menu.text, Commons.Color.accent)
        : Commons.Style.normalStateColor(Commons.Color.menu.text, Commons.Color.accent)
    radius: Commons.Style.cornerRadius
    borderSpec: Commons.Border.controlSpec(controlState, Commons.Color.menu.text, Commons.Color.accent)
    color: pressed ? Commons.Style.pressedFillFor(Commons.Color.menu.text, Commons.Color.accent)
        : focused ? Commons.Style.focusFillFor(Commons.Color.menu.text, Commons.Color.accent)
        : hovered ? Commons.Style.hoverFillFor(Commons.Color.menu.text, Commons.Color.accent)
        : selected ? Commons.Style.selectedFillFor(Commons.Color.menu.text, Commons.Color.accent)
        : Commons.Style.normalFillFor(Commons.Color.menu.text, Commons.Color.accent)
}

import QtQuick
import "CrtLayout.js" as CrtLayout
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// One window as a line of the CRT list: number, workspace, application, and
// title in fixed columns, typed in while the look boots. The selected line is
// drawn dark on the look's cursor bar. Hover selects; a click opens.
Item {
    id: line

    required property var modelData
    required property var stack
    readonly property var controller: stack.overview

    readonly property int slot: stack.toplevels.indexOf(modelData)
    readonly property bool inLayout: slot >= 0
    readonly property bool selected: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.selection
    readonly property bool previewed: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.previewToplevel
    readonly property string fullText: CrtLayout.row(slot + 1, controller.workspaceName(modelData),
        CrtLayout.appName(WindowModel.appIdFor(modelData)), String(modelData.title || "untitled"))
    readonly property real progress: CrtLayout.typed(Math.max(0, slot), stack.toplevels.length, stack.boot)

    visible: inLayout && progress > 0
    x: 0
    y: slot * stack.rowHeight
    width: stack.listWidth
    height: stack.rowHeight

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Commons.Style.space(10)
        anchors.rightMargin: Commons.Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
        text: line.fullText.slice(0, Math.ceil(line.fullText.length * line.progress))
            + (line.progress < 1 ? "█" : "")
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: line.stack.phosphor
        opacity: line.selected || line.modelData === line.controller.originToplevel ? 1 : 0.62
        font.family: Commons.Style.font.family
        font.pixelSize: Commons.Style.font.heading
        font.bold: line.selected
    }

    CardPointer {
        controller: line.controller
        toplevel: line.modelData
        acceptsKeyboard: line.stack.screenWindow.acceptsKeyboard
        selected: line.selected
        previewed: line.previewed
        hoverSelects: true
    }
}

import QtQuick
import QtQuick.Layouts
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// A window's name in large type with its icon, and one line of detail under
// it; looks place it below whatever they draw. Empty while `toplevel` is null.
ColumnLayout {
    id: caption

    required property var overview
    required property var toplevel
    property string detail: ""

    spacing: Commons.Style.spacing.sm
    visible: toplevel !== null

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: caption.width
        spacing: Commons.Style.spacing.lg

        Image {
            Layout.preferredWidth: Commons.Style.space(36)
            Layout.preferredHeight: Commons.Style.space(36)
            source: caption.toplevel ? caption.overview.iconFor(caption.toplevel) : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Text {
            Layout.maximumWidth: caption.width - Commons.Style.space(60)
            text: caption.toplevel ? String(caption.toplevel.title || WindowModel.appIdFor(caption.toplevel) || "Untitled window") : ""
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Commons.Color.menu.text
            font.family: Commons.Style.font.menuFamily
            font.pixelSize: Commons.Style.font.displayLarge
            font.bold: true
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: caption.detail
        textFormat: Text.PlainText
        color: Commons.Color.menu.text
        opacity: 0.6
        font.family: Commons.Style.font.menuFamily
        font.pixelSize: Commons.Style.font.heading
    }
}

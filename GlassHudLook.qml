import QtQuick
import qs.Commons as Commons

// The glass HUD look: frosted glass cards on the grid's balanced rows, each
// window's title in large type, and one gradient ring sweeping around the
// selection that travels from card to card.
Look {
    id: look

    readonly property var toplevels: screenWindow.screenToplevels
    readonly property int selectedIndex: toplevels.indexOf(overview.selection)
    readonly property real headerHeight: Commons.Style.space(56)
    // Under each thumbnail: the title in large type and a readout line.
    readonly property real titleBandHeight: Commons.Style.space(64)
    readonly property real cardPadding: Commons.Style.space(14)
    readonly property real cardRadius: Commons.Style.space(14)

    windowLayout: {
        var revision = overview.modelRevision;
        var screenRatio = screenWindow.screen && screenWindow.screen.height > 0
            ? screenWindow.screen.width / screenWindow.screen.height
            : 0;
        return overview.computeWindowLayout(toplevels, field.width, field.height, Commons.Style.space(40), cardPadding, titleBandHeight, screenRatio);
    }

    // The readout across the top.
    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Commons.Style.space(40)
        anchors.rightMargin: Commons.Style.space(40)
        height: look.headerHeight

        HudText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "WINDOWS " + String(look.toplevels.length).padStart(2, "0") + "   ▸   "
                + (look.overview.workspaceScope === "current" ? "WORKSPACE " + look.screenWindow.screenWorkspaceLabel : "ALL WORKSPACES")
                + (look.overview.filterText ? "   ▸   FILTER \"" + look.overview.filterText + "\"" : "")
        }

        HudText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: look.selectedIndex >= 0
            color: Commons.Color.accent
            text: "SELECTED " + String(look.selectedIndex + 1).padStart(2, "0") + " / " + String(look.toplevels.length).padStart(2, "0")
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(Commons.Color.accent, 0.7) }
                GradientStop { position: 0.5; color: Qt.alpha(Commons.Color.menu.text, 0.15) }
                GradientStop { position: 1; color: Qt.alpha(Commons.Color.accent, 0.7) }
            }
        }
    }

    Item {
        id: field
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Repeater {
            model: look.screenWindow.cardToplevels

            delegate: GlassHudCard {
                stack: look
                areaWidth: field.width
                areaHeight: field.height
            }
        }

        HudRing {
            overview: look.overview
            target: look.selectedIndex >= 0 ? look.windowLayout[look.selectedIndex] || null : null
            shown: look.screenWindow.acceptsKeyboard && target !== null && !look.overview.previewToplevel
            label: String(look.selectedIndex + 1).padStart(2, "0")
            radius: look.cardRadius + Commons.Style.space(8)
        }
    }

    component HudText: Text {
        textFormat: Text.PlainText
        color: Commons.Color.menu.text
        opacity: 0.8
        font.family: Commons.Style.font.family
        font.pixelSize: Commons.Style.font.body
        font.letterSpacing: Commons.Style.space(2)
    }
}

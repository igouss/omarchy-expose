import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons // qmllint disable import
import qs.Ui as Ui // qmllint disable import

Item {
    id: keyCatcher
    property var overview: null
    property var screenWindow: null
    readonly property alias settingsLayer: settingsLayerLoader
    anchors.fill: parent
    focus: screenWindow.acceptsKeyboard
    enabled: overview.opened
    scale: overview.animationStyle === "zoom"
        ? 0.82 + 0.18 * overview.motionProgress
        : (overview.animationStyle === "slide"
            ? 0.97 + 0.03 * overview.motionProgress
            : (overview.animationStyle === "original"
                ? 0.96 + 0.04 * overview.motionProgress
                : 1))
    transformOrigin: Item.Center
    transform: Translate {
        x: screenWindow.width * overview.slideOffsetFraction * overview.slideVector.x
        y: screenWindow.height * overview.slideOffsetFraction * overview.slideVector.y
    }
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: function (event) {
        if (overview.settingsOpen
                && !overview.footerHideConfirmationOpen
                && event.key >= Qt.Key_1
                && event.key <= Qt.Key_6) {
            overview.settingsCategoryIndex = event.key - Qt.Key_1;
            Qt.callLater(screenWindow.focusSettingsCategory);
            event.accepted = true;
            return;
        }
        if (overview.handleSettingsNavigation(event))
            return;
        overview.handleKey(event, overviewArea.windowLayout);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.spacing.sm
        spacing: Style.spacing.md

        Ui.BorderSurface {
            id: searchBar
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(Style.space(760), screenWindow.width - Style.space(48))
            Layout.preferredHeight: Style.space(48)
            radius: Style.cornerRadius
            color: Color.menu.background
            borderSpec: Border.surfaceSpec("menu", "border", Color.foreground, Style.normalBorderWidth)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.spacing.xl
                anchors.rightMargin: Style.spacing.xl
                spacing: Style.spacing.md
                Text {
                    text: "⌕"
                    textFormat: Text.PlainText
                    color: Color.menu.text
                    font.family: Style.font.menuFamily
                    font.pixelSize: Style.font.heading
                }
                Text {
                    Layout.fillWidth: true
                    text: overview.filterText || "Type to filter windows…"
                    textFormat: Text.PlainText
                    color: Color.menu.text
                    opacity: overview.filterText ? 1 : 0.6
                    font.family: Style.font.menuFamily
                    font.pixelSize: Style.font.heading
                    elide: Text.ElideRight
                }
                Text {
                    text: screenWindow.screenToplevels.length + " windows"
                    textFormat: Text.PlainText
                    color: Color.menu.text
                    opacity: 0.55
                    font.family: Style.font.menuFamily
                    font.pixelSize: Style.font.bodySmall
                }

                ThemeDivider {
                    vertical: true
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: Style.space(24)
                }

                Text {
                    Layout.maximumWidth: Style.space(176)
                    text: searchBar.width < Style.space(640)
                        ? (overview.workspaceScope === "all" ? "All" : "WS " + screenWindow.screenWorkspaceLabel)
                        : screenWindow.screenScopeLabel
                    textFormat: Text.PlainText
                    color: Color.accent
                    font.family: Style.font.menuFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                    elide: Text.ElideRight
                }

                ThemedControl {
                    Layout.preferredWidth: Style.space(34)
                    Layout.preferredHeight: Style.space(24)
                    radius: Math.max(0, Style.cornerRadius - Style.spacing.sm)
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Tab"
                        textFormat: Text.PlainText
                        color: Color.menu.text
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.caption
                    }
                }
            }
        }

        Item {
            id: overviewArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            readonly property var windowLayout: {
                var revision = overview.modelRevision;
                var screenRatio = screenWindow.screen && screenWindow.screen.height > 0
                    ? screenWindow.screen.width / screenWindow.screen.height
                    : 0;
                return overview.computeWindowLayout(screenWindow.screenToplevels, width, height, Style.space(64), Style.spacing.sm, overview.windowFooterHeight, screenRatio);
            }

            Item {
                id: cardLayer
                anchors.fill: parent
                // The original style grows the whole arrangement out of the
                // top-left corner. A single transform does that without
                // resizing any card, so no layout, text elision, or layer
                // texture is redone per frame.
                scale: overview.animationStyle === "original" && overview.motionTarget > 0
                    ? overview.motionProgress
                    : 1
                transformOrigin: Item.TopLeft

                Repeater {
                    model: screenWindow.cardToplevels

                    delegate: WindowCard {
                        controller: overview
                        screenToplevels: screenWindow.screenToplevels
                        acceptsKeyboard: screenWindow.acceptsKeyboard
                        windowLayout: overviewArea.windowLayout
                        layoutAreaWidth: overviewArea.width
                        layoutAreaHeight: overviewArea.height
                    }
                    }
            }

            Text {
                anchors.centerIn: parent
                visible: screenWindow.screenToplevels.length === 0
                text: overview.filterText
                    ? "No matching windows"
                    : (overview.workspaceScope === "current"
                        ? "No windows on Workspace " + screenWindow.screenWorkspaceLabel
                        : "No open windows")
                textFormat: Text.PlainText
                color: Color.menu.text
                opacity: 0.7
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.display
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Style.spacing.xl
            visible: overview.showFooter

            Text {
                text: "← ↑ ↓ → navigate   Space preview   Tab scope   Shift+Q close   Enter open   Esc close"
                textFormat: Text.PlainText
                color: Color.menu.text
                opacity: 0.55
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.bodySmall
            }

            Text {
                id: settingsControl
                property bool hovered: false
                text: "Settings"
                textFormat: Text.PlainText
                color: settingsControl.hovered ? Style.hoverStateColor(Color.menu.text, Color.accent) : Color.menu.text
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: settingsControl.hovered = true
                    onExited: settingsControl.hovered = false
                    onClicked: overview.openSettings()
                }
            }
        }
    }

    Loader {
        id: settingsLayerLoader
        anchors.fill: parent
        active: overview.settingsOpen
        z: 200
        onLoaded: {
            if (screenWindow.acceptsKeyboard)
                Qt.callLater(screenWindow.focusSettingsCategory);
        }

        sourceComponent: Component {
            SettingsView {
                controller: overview
                hostWindow: screenWindow
            }
        }
    }
}

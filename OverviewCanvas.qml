import QtQuick
import QtQuick.Layouts
import "SettingsSchema.js" as SettingsSchema
import qs.Commons as Commons
import qs.Ui as Ui

Item {
    id: keyCatcher
    property var overview: null
    property var screenWindow: null
    readonly property SettingsView settings: settingsLayerLoader.item as SettingsView
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
                && event.key < Qt.Key_1 + SettingsSchema.categories.length) {
            overview.settingsCategoryIndex = event.key - Qt.Key_1;
            Qt.callLater(() => keyCatcher.settings?.focusSettingsCategory());
            event.accepted = true;
            return;
        }
        if (overview.handleSettingsNavigation(event))
            return;
        overview.handleKey(event, lookLoader.item ? (lookLoader.item as Look).windowLayout : []);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Commons.Style.spacing.sm
        spacing: Commons.Style.spacing.md

        Ui.BorderSurface {
            id: searchBar
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(Commons.Style.space(760), screenWindow.width - Commons.Style.space(48))
            Layout.preferredHeight: Commons.Style.space(48)
            radius: Commons.Style.cornerRadius
            color: Commons.Color.menu.background
            borderSpec: Commons.Border.surfaceSpec("menu", "border", Commons.Color.foreground, Commons.Style.normalBorderWidth)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Commons.Style.spacing.xl
                anchors.rightMargin: Commons.Style.spacing.xl
                spacing: Commons.Style.spacing.md
                Text {
                    text: "⌕"
                    textFormat: Text.PlainText
                    color: Commons.Color.menu.text
                    font.family: Commons.Style.font.menuFamily
                    font.pixelSize: Commons.Style.font.heading
                }
                Text {
                    Layout.fillWidth: true
                    text: overview.filterText || "Type to filter windows…"
                    textFormat: Text.PlainText
                    color: Commons.Color.menu.text
                    opacity: overview.filterText ? 1 : 0.6
                    font.family: Commons.Style.font.menuFamily
                    font.pixelSize: Commons.Style.font.heading
                    elide: Text.ElideRight
                }
                Text {
                    text: screenWindow.screenToplevels.length + " windows"
                    textFormat: Text.PlainText
                    color: Commons.Color.menu.text
                    opacity: 0.55
                    font.family: Commons.Style.font.menuFamily
                    font.pixelSize: Commons.Style.font.bodySmall
                }

                ThemeDivider {
                    vertical: true
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: Commons.Style.space(24)
                }

                Text {
                    Layout.maximumWidth: Commons.Style.space(176)
                    text: searchBar.width < Commons.Style.space(640)
                        ? (overview.workspaceScope === "all" ? "All" : "WS " + screenWindow.screenWorkspaceLabel)
                        : screenWindow.screenScopeLabel
                    textFormat: Text.PlainText
                    color: Commons.Color.accent
                    font.family: Commons.Style.font.menuFamily
                    font.pixelSize: Commons.Style.font.bodySmall
                    font.bold: true
                    elide: Text.ElideRight
                }

                ThemedControl {
                    Layout.preferredWidth: Commons.Style.space(34)
                    Layout.preferredHeight: Commons.Style.space(24)
                    radius: Math.max(0, Commons.Style.cornerRadius - Commons.Style.spacing.sm)
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Tab"
                        textFormat: Text.PlainText
                        color: Commons.Color.menu.text
                        font.family: Commons.Style.font.menuFamily
                        font.pixelSize: Commons.Style.font.caption
                    }
                }
            }
        }

        Item {
            id: overviewArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            // One Component per look, keyed by the look setting's value.
            readonly property var looks: ({ grid: gridLook })

            Component {
                id: gridLook
                GridLook {
                    overview: keyCatcher.overview
                    screenWindow: keyCatcher.screenWindow
                }
            }

            Loader {
                id: lookLoader
                anchors.fill: parent
                sourceComponent: overviewArea.looks[overview.look] || overviewArea.looks.grid
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
                color: Commons.Color.menu.text
                opacity: 0.7
                font.family: Commons.Style.font.menuFamily
                font.pixelSize: Commons.Style.font.display
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Commons.Style.spacing.xl
            visible: overview.showFooter

            Text {
                text: "← ↑ ↓ → navigate   Space preview   Tab scope   Shift+Q close   Enter open   Esc close"
                textFormat: Text.PlainText
                color: Commons.Color.menu.text
                opacity: 0.55
                font.family: Commons.Style.font.menuFamily
                font.pixelSize: Commons.Style.font.bodySmall
            }

            Text {
                id: settingsControl
                property bool hovered: false
                text: "Settings"
                textFormat: Text.PlainText
                color: settingsControl.hovered ? Commons.Style.hoverStateColor(Commons.Color.menu.text, Commons.Color.accent) : Commons.Color.menu.text
                font.family: Commons.Style.font.menuFamily
                font.pixelSize: Commons.Style.font.bodySmall
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
                Qt.callLater(() => keyCatcher.settings?.focusSettingsCategory());
        }

        sourceComponent: Component {
            SettingsView {
                controller: overview
                hostWindow: screenWindow
            }
        }
    }
}

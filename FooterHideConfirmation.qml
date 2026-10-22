import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import qs.Ui as Ui

Item {
    id: footerHideConfirmationLayer
    property var view: null
    property var bottomTextToggle: null
    readonly property var focusControls: [footerHideAcknowledgement, footerHideCancelButton, footerHideConfirmButton]
    anchors.fill: parent
    visible: view.controller.footerHideConfirmationOpen
    z: 10
    onVisibleChanged: {
        if (visible && view.hostWindow.acceptsKeyboard)
            Qt.callLater(function () {
                if (footerHideConfirmationLayer.visible)
                    footerHideAcknowledgement.forceActiveFocus();
            });
        else if (!visible && view.controller.settingsOpen && view.hostWindow.acceptsKeyboard)
            Qt.callLater(function () {
                if (!view.visible || footerHideConfirmationLayer.visible)
                    return;
                if (view.controller.settingsCategoryIndex === 0
                        && bottomTextToggle.visible && bottomTextToggle.enabled)
                    bottomTextToggle.forceActiveFocus();
                else
                    view.focusSettingsCategory();
            });
    }

    MouseArea {
        anchors.fill: parent
        onClicked: view.controller.closeFooterHideConfirmation()
    }

    Rectangle {
        anchors.fill: parent
        color: Commons.Color.menu.scrim
    }

    Ui.BorderSurface {
        id: footerHideDialog
        anchors.centerIn: parent
        width: Math.min(Commons.Style.space(560), parent.width - Commons.Style.space(80))
        height: Math.min(parent.height - Commons.Style.space(80), footerHideContent.implicitHeight + Commons.Style.space(56))
        radius: Commons.Style.cornerRadius
        color: Commons.Color.menu.background
        borderSpec: Commons.Border.surfaceSpec("menu", "border", Commons.Color.foreground, Commons.Style.normalBorderWidth)

        MouseArea {
            anchors.fill: parent
            onClicked: function (mouse) { mouse.accepted = true; }
        }

        ColumnLayout {
            id: footerHideContent
            anchors.fill: parent
            anchors.margins: Commons.Style.space(28)
            spacing: Commons.Style.spacing.lg

            Text {
                Layout.fillWidth: true
                text: "Hide bottom text?"
                textFormat: Text.PlainText
                color: Commons.Color.menu.text
                font.family: Commons.Style.font.menuFamily
                font.pixelSize: Commons.Style.font.heading
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "This also hides the Settings link. You can turn it back on while this panel remains open."
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: Commons.Color.menu.text
                font.family: Commons.Style.font.menuFamily
                font.pixelSize: Commons.Style.font.body
            }

            ThemedControl {
                Layout.fillWidth: true
                Layout.preferredHeight: recoveryText.implicitHeight + Commons.Style.space(24)

                Text {
                    id: recoveryText
                    anchors.fill: parent
                    anchors.margins: Commons.Style.space(12)
                    text: "After closing Settings, restore it in ~/.config/omarchy/shell.json by setting showFooter to true in the elendal.panorama plugin entry."
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    color: Commons.Color.menu.text
                    opacity: 0.72
                    font.family: Commons.Style.font.menuFamily
                    font.pixelSize: Commons.Style.font.caption
                }
            }

            Item {
                id: footerHideAcknowledgement
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(Commons.Style.space(40), acknowledgementText.implicitHeight)
                activeFocusOnTab: true

                Keys.onPressed: function (event) {
                    if (view.controller.handleSettingsNavigation(event))
                        return;
                    if (event.key !== Qt.Key_Space && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter) {
                        event.accepted = false;
                        return;
                    }
                    view.controller.footerHideAcknowledged = !view.controller.footerHideAcknowledged;
                    event.accepted = true;
                }

                RowLayout {
                    id: acknowledgementRow
                    anchors.fill: parent
                    spacing: Commons.Style.spacing.md

                    ThemedControl {
                        id: acknowledgementBox
                        Layout.preferredWidth: Commons.Style.space(18)
                        Layout.preferredHeight: Commons.Style.space(18)
                        selected: view.controller.footerHideAcknowledged
                        focused: footerHideAcknowledgement.activeFocus

                        Text {
                            anchors.centerIn: parent
                            visible: view.controller.footerHideAcknowledged
                            text: "✓"
                            textFormat: Text.PlainText
                            color: acknowledgementBox.stateColor
                            font.family: Commons.Style.font.menuFamily
                            font.pixelSize: Commons.Style.font.caption
                            font.bold: true
                        }
                    }

                    Text {
                        id: acknowledgementText
                        Layout.fillWidth: true
                        text: "I understand that closing Settings while it is hidden requires editing the config."
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                        color: Commons.Color.menu.text
                        font.family: Commons.Style.font.menuFamily
                        font.pixelSize: Commons.Style.font.bodySmall
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: footerHideAcknowledgement.forceActiveFocus()
                    onClicked: view.controller.footerHideAcknowledged = !view.controller.footerHideAcknowledged
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Commons.Style.spacing.sm
                spacing: Commons.Style.spacing.md

                Item { Layout.fillWidth: true }

                DialogButton {
                    id: footerHideCancelButton
                    view: footerHideConfirmationLayer.view
                    label: "Cancel"
                    onClicked: view.controller.closeFooterHideConfirmation()
                }

                DialogButton {
                    id: footerHideConfirmButton
                    view: footerHideConfirmationLayer.view
                    label: "Hide bottom text"
                    destructive: true
                    enabled: view.controller.footerHideAcknowledged
                    onClicked: view.controller.confirmFooterHide()
                }
            }
        }
    }
}

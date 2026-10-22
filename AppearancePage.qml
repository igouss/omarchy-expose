import QtQuick
import QtQuick.Layouts

SettingsPage {
    id: page
    readonly property var focusControls: [backgroundBlurSlider, backgroundDimSlider, bottomTextToggle]
    readonly property alias bottomTextToggleItem: bottomTextToggle
    categoryIndex: 0
    title: "Backdrop and bottom text"

    SettingRow {
        dialog: page.dialog
        label: "Background blur"
        description: "Soften the desktop behind the overview. Set to 0 for no blur."

        SettingSlider {
            id: backgroundBlurSlider
            view: page.view
            Layout.fillWidth: true
            from: 0
            to: 20
            value: view.controller.effectiveBackgroundBlur
            suffix: " px"
            onEdited: function (value) { view.controller.backgroundBlurPreview = value; }
            onCommitted: function (value) {
                view.controller.backgroundBlurPreview = Math.round(value);
                view.controller.setBackgroundBlur(value);
            }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Background dim"
        description: "Darken the desktop behind the overview. Higher values make it darker."

        SettingSlider {
            id: backgroundDimSlider
            view: page.view
            Layout.fillWidth: true
            from: 0
            to: 90
            value: view.controller.effectiveBackgroundDim
            suffix: "%"
            onEdited: function (value) { view.controller.backgroundDimPreview = value; }
            onCommitted: function (value) {
                view.controller.backgroundDimPreview = Math.round(value);
                view.controller.setBackgroundDim(value);
            }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Bottom text"
        description: "Show keyboard hints and the Settings link below the grid. Hiding it requires confirmation."

        Item { Layout.fillWidth: true }

        SettingToggle {
            id: bottomTextToggle
            view: page.view
            checked: view.controller.showFooter
            onToggled: function (checked) {
                if (checked)
                    view.controller.updatePluginSetting("showFooter", true);
                else
                    view.controller.requestFooterHide();
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "SettingsSchema.js" as SettingsSchema

SettingsPage {
    id: page
    readonly property var focusControls: [lookChoices]
    categoryIndex: 0
    title: "How the overview looks"

    SettingRow {
        dialog: page.dialog
        label: "Look"
        description: SettingsSchema.options("look").filter(option => option.value === view.controller.look)[0].description

        SettingChoices {
            id: lookChoices
            view: page.view
            Layout.fillWidth: true
            value: view.controller.look
            options: SettingsSchema.options("look")
            onChosen: function (value) { view.controller.setSetting("look", value); }
        }
    }
}

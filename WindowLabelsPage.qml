import QtQuick
import "SettingsSchema.js" as SettingsSchema
import QtQuick.Layouts
import qs.Commons as Commons

SettingsPage {
    id: page
    readonly property var focusControls: [windowFooterChoices, workspaceLabelStyleChoices]
    categoryIndex: 3
    title: "Titles and workspace names"

    SettingRow {
        dialog: page.dialog
        label: "Window labels"
        description: "Choose how the app, title, and workspace label sit around each preview."

        SettingChoices {
            id: windowFooterChoices
            view: page.view
            Layout.fillWidth: true
            value: view.controller.windowFooterStyle
            spacing: Commons.Style.spacing.md
            options: SettingsSchema.options("windowFooterStyle")
            onChosen: function (value) { view.controller.setSetting("windowFooterStyle", value); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Workspace names"
        description: "Slot only shortens names such as “Monitor:3” to “3”. Other names stay unchanged."

        SettingChoices {
            id: workspaceLabelStyleChoices
            view: page.view
            Layout.fillWidth: true
            value: view.controller.workspaceLabelStyle
            options: SettingsSchema.options("workspaceLabelStyle")
            onChosen: function (value) { view.controller.setSetting("workspaceLabelStyle", value); }
        }
    }
}

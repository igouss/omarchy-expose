import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons

SettingsPage {
    id: page
    readonly property var focusControls: [windowFooterChoices, workspaceLabelStyleChoices]
    categoryIndex: 2
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
            options: [
                { label: "Floating", value: "floating" },
                { label: "Rail", value: "integrated" },
                { label: "Overlay", value: "overlay" },
                { label: "Centered", value: "centered" }
            ]
            onChosen: function (value) { view.controller.setWindowFooterStyle(value); }
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
            options: [
                { label: "Full", value: "full" },
                { label: "Slot only", value: "slot" }
            ]
            onChosen: function (value) { view.controller.setWorkspaceLabelStyle(value); }
        }
    }
}

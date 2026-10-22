import QtQuick
import QtQuick.Layouts

SettingsPage {
    id: page
    readonly property var focusControls: [initialWorkspaceScopeChoices, displayModeChoicesControl]
    categoryIndex: 3
    title: "Which windows you see"

    SettingRow {
        dialog: page.dialog
        label: "Open with"
        description: "Choose which workspaces are shown when Exposé opens. Press Tab in the overview to switch."

        SettingChoices {
            id: initialWorkspaceScopeChoices
            view: page.view
            Layout.fillWidth: true
            value: view.controller.initialWorkspaceScope
            options: [
                { label: "All workspaces", value: "all" },
                { label: "Current", value: "current" }
            ]
            onChosen: function (value) { view.controller.setInitialWorkspaceScope(value); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Windows to include"
        description: "The grid stays on the display where Exposé opened. With This display and Current, use the workspace active on that display."
        stacked: true

        DisplayModeChoices {
            id: displayModeChoicesControl
            view: page.view
            Layout.fillWidth: true
            value: view.controller.multiMonitorMode
            onChosen: function (value) { view.controller.setMultiMonitorMode(value); }
        }
    }
}

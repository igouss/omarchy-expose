import QtQuick

// The scoped host can replace our entry, but cannot expose it for reading.
// Keep edits visible locally and allow only one unconfirmed replacement at a time.
QtObject {
    id: root

    required property string pluginId
    property var shell: null
    property bool ready: false
    property var diskEntry: null
    property var pending: ({})
    property var inFlight: null
    property bool recovering: false
    readonly property var entry: {
        var next = Object.assign({}, root.inFlight || root.diskEntry || {});
        return Object.assign(next, root.pending);
    }

    signal reloadRequested()

    property Timer confirmationTimeout: Timer {
        interval: 2000
        onTriggered: root.reconcile()
    }

    function contains(entry, expected) {
        if (!entry)
            return false;
        for (let key in expected)
            if (JSON.stringify(entry[key]) !== JSON.stringify(expected[key]))
                return false;
        return true;
    }

    function load(raw) {
        var config;
        try {
            config = JSON.parse(raw);
            if (!config || Array.isArray(config) || config.version !== 1)
                throw new Error("expected shell.json version 1");
        } catch (error) {
            root.loadFailed();
            console.warn(root.pluginId + ": could not read settings: " + error);
            return;
        }

        var plugins = Array.isArray(config.plugins) ? config.plugins : [];
        var next = null;
        for (let i = 0; i < plugins.length; i++) {
            if (plugins[i] && plugins[i].id === root.pluginId) {
                next = plugins[i];
                break;
            }
        }
        root.diskEntry = next;
        root.ready = true;
        if (root.inFlight && root.contains(next, root.inFlight)) {
            root.inFlight = null;
            root.confirmationTimeout.stop();
        } else if (root.recovering) {
            root.discardEdits();
            console.warn(root.pluginId + ": settings write was not confirmed; restored disk settings");
        }
        root.recovering = false;
        // FileView still owns its read job during onLoaded. Let it finish
        // before a write or another reload can run.
        Qt.callLater(root.flush);
    }

    function loadFailed() {
        root.ready = false;
        if (root.recovering)
            root.discardEdits();
    }

    function discardEdits() {
        root.confirmationTimeout.stop();
        root.inFlight = null;
        root.pending = ({});
        root.recovering = false;
    }

    function reconcile() {
        root.recovering = true;
        root.reloadRequested();
    }

    function update(name, value) {
        if (name === "id" || !root.shell || typeof root.shell.updateEntryInline !== "function")
            return false;
        var next = Object.assign({}, root.pending);
        next[name] = JSON.parse(JSON.stringify(value));
        root.pending = next;
        Qt.callLater(root.flush);
        return true;
    }

    function flush() {
        if (!root.ready || root.inFlight || Object.keys(root.pending).length === 0
                || !root.shell || typeof root.shell.updateEntryInline !== "function")
            return;
        if (!root.diskEntry) {
            root.discardEdits();
            console.warn(root.pluginId + ": cannot save settings without a configured plugin entry");
            return;
        }
        var next = Object.assign({}, root.diskEntry, root.pending);
        if (root.contains(root.diskEntry, next)) {
            root.pending = ({});
            return;
        }
        root.inFlight = next;
        root.pending = ({});
        var settings = Object.assign({}, next);
        delete settings.id;
        try {
            // false also means unchanged, and true only acknowledges the
            // host's in-memory update. Disk observation confirms either case.
            root.shell.updateEntryInline(root.pluginId, settings);
            root.confirmationTimeout.restart();
            root.reloadRequested();
        } catch (error) {
            root.discardEdits();
            console.warn(root.pluginId + ": could not save settings: " + error);
            root.reloadRequested();
        }
    }
}

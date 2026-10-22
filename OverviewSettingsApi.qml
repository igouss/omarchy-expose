import QtQuick
import "SettingsSchema.js" as SettingsSchema

// Validated setters behind the settings panel and IPC.
OverviewState {
    id: root

    // Stores a simple setting from the schema; returns the value it now has.
    function setSetting(name, value) {
        var next = SettingsSchema.normalize(name, value, root[name]);
        if (next !== root[name])
            root.updatePluginSetting(name, next);
        return next;
    }

    // IPC form of setSetting: rejects unlisted options and non on/off booleans
    // with a message, and answers with the stored value as text.
    function setSettingFromIpc(name, text) {
        var parsed = SettingsSchema.parseIpc(name, text);
        if (parsed.error)
            return parsed.error;
        var next = name === "hotCornerEnabled" ? root.setHotCornerEnabled(parsed.value) : root.setSetting(name, parsed.value);
        return typeof next === "boolean" ? (next ? "on" : "off") : String(next);
    }





    function setAnimationTiming(style, inValue, outValue, separate) {
        var mode = root.animationStyles.indexOf(style) !== -1 ? style : "original";
        var nextIn = root.clampAnimationDuration(inValue);
        var nextOut = root.clampAnimationDuration(outValue);
        var nextSeparate = separate === true;
        if (mode === "slide" && !nextSeparate)
            root.setSlideDirection(root.slideDirection["in"]);
        var current = root.animationTimingFor(mode);
        if (nextIn !== Number(current["in"])
                || nextOut !== Number(current["out"])
                || nextSeparate !== (current.separate === true)) {
            let timings = {};
            for (let index = 0; index < root.animationStyles.length; index++) {
                let animationMode = root.animationStyles[index];
                let timing = root.animationTimingFor(animationMode);
                timings[animationMode] = animationMode === mode
                    ? {"in": nextIn, "out": nextOut, separate: nextSeparate}
                    : {"in": Number(timing["in"]), "out": Number(timing["out"]), separate: timing.separate === true};
            }
            root.updatePluginSetting("animationTimings", timings);
        }
        return {"in": nextIn, "out": nextOut, separate: nextSeparate};
    }

    function setAnimationDuration(style, value) {
        var next = root.clampAnimationDuration(value);
        root.setAnimationTiming(style, next, next, false);
        return next;
    }

    function setAnimationDurationIn(style, value) {
        var timing = root.animationTimingFor(style);
        var next = root.clampAnimationDuration(value);
        root.setAnimationTiming(style, next, timing["out"], true);
        return next;
    }

    function setAnimationDurationOut(style, value) {
        var timing = root.animationTimingFor(style);
        var next = root.clampAnimationDuration(value);
        root.setAnimationTiming(style, timing["in"], next, true);
        return next;
    }

    function setAnimationTimingSeparate(style, separate) {
        var timing = root.animationTimingFor(style);
        return separate
            ? root.setAnimationTiming(style, timing["in"], timing["out"], true)
            : root.setAnimationTiming(style, timing["in"], timing["in"], false);
    }

    function setSlideDirections(inValue, outValue) {
        var nextIn = root.normalizeSlideDirection(inValue);
        var nextOut = root.normalizeSlideDirection(outValue);
        var current = root.slideDirection;
        if (nextIn !== String(current["in"]) || nextOut !== String(current["out"]))
            root.updatePluginSetting("slideDirection", {"in": nextIn, "out": nextOut});
    }

    function setSlideDirection(value) {
        var next = root.normalizeSlideDirection(value);
        root.setSlideDirections(next, next);
        return next;
    }

    // Splitting a side also splits slide timing: one toggle governs both.
    function setSlideDirectionIn(value) {
        var next = root.normalizeSlideDirection(value);
        root.setAnimationTimingSeparate("slide", true);
        root.setSlideDirections(next, root.slideDirection["out"]);
        return next;
    }

    function setSlideDirectionOut(value) {
        var next = root.normalizeSlideDirection(value);
        root.setAnimationTimingSeparate("slide", true);
        root.setSlideDirections(root.slideDirection["in"], next);
        return next;
    }

    function clearAnimationTimingPreview() {
        root.animationDurationPreviewStyle = "";
        root.animationInDurationPreview = -1;
        root.animationOutDurationPreview = -1;
    }

    function clearSettingsPreviews() {
        root.clearAnimationTimingPreview();
        root.backgroundBlurPreview = -1;
        root.backgroundDimPreview = -1;
        root.hotCornerDelayPreview = -1;
    }



    function setHotCornerEnabled(enabled) {
        var next = enabled === true;
        // The corner is also disabled while settings load; an early "off"
        // command must still be queued even though the surface is inactive.
        root.updatePluginSetting("hotCornerEnabled", next);
        return next;
    }








    function requestFooterHide() {
        if (!root.showFooter)
            return;
        root.footerHideAcknowledged = false;
        root.footerHideConfirmationOpen = true;
    }

    function closeFooterHideConfirmation() {
        root.footerHideConfirmationOpen = false;
        root.footerHideAcknowledged = false;
    }

    function confirmFooterHide() {
        if (!root.footerHideConfirmationOpen || !root.footerHideAcknowledged || !root.showFooter)
            return;
        root.updatePluginSetting("showFooter", false);
        root.closeFooterHideConfirmation();
    }

    // IPC rejection text derived from the option list it validates against.
}

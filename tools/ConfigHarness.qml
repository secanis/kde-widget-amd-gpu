/*
    Standalone host for the settings page, for previewing it outside the
    Plasma configuration dialog:  make config-preview

    The dialog normally provides i18n() through KLocalizedContext and the
    cfg_* values from the applet configuration; stand-ins are defined here.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import "../package/contents/ui/config" as Cfg

QQC2.ApplicationWindow {
    id: harness
    title: "ConfigHarness"
    width: 620
    height: 820
    visible: true

    function i18n(s, a, b, c) { return s.replace("%1", a ?? "").replace("%2", b ?? "").replace("%3", c ?? "") }
    function i18np(s, p, n) { return (n === 1 ? s : p).replace("%1", n) }
    function i18nc(ctx, s, a, b) { return i18n(s, a, b) }

    Cfg.ConfigGeneral {
        anchors.fill: parent
        cfg_gpuIndex: 0
        cfg_updateInterval: 1000
        cfg_showUsage: true
        cfg_showVram: true
        cfg_showTemperature: true
        cfg_verticalMargin: 2
        cfg_useCustomColors: false
        cfg_usageColor: "#3daee9"
        cfg_vramColor: "#27ae60"
        cfg_temperatureColor: "#f67400"
        cfg_showHistory: true
        cfg_historySeconds: 60
    }
}

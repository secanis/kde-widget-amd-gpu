/*
    Minimal host for the panel view only, using a plain Window so it can run
    with the Plasma Qt Quick Controls style (the one plasmashell uses):
      QT_QUICK_CONTROLS_STYLE=Plasma qml6 tools/CompactHarness.qml

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../package/contents/ui" as Widget

Window {
    id: harness
    title: "CompactHarness"
    width: 420
    height: 260
    visible: true
    color: "#1b1e28"

    function i18n(s, a, b, c) { return s.replace("%1", a ?? "").replace("%2", b ?? "").replace("%3", c ?? "") }
    function i18np(s, p, n) { return (n === 1 ? s : p).replace("%1", n) }
    function i18nc(ctx, s, a, b) { return i18n(s, a, b) }

    Widget.GpuSensors { id: gpu; gpuId: "gpu/gpu0" }
    Widget.GpuSensors { id: missingGpu; gpuId: "gpu/gpu7" }

    Column {
        anchors { fill: parent; margins: 12 }
        spacing: 8
        Repeater {
            model: [ { h: 24, s: 0, g: gpu }, { h: 32, s: 3, g: gpu }, { h: 40, s: 2, g: gpu }, { h: 32, s: 0, g: missingGpu } ]
            Rectangle {
                required property var modelData
                color: "#2a2e3a"
                width: compact.Layout.preferredWidth + 8
                height: modelData.h
                Widget.CompactRepresentation {
                    id: compact
                    gpu: parent.modelData.g
                    anchors { top: parent.top; bottom: parent.bottom; left: parent.left; leftMargin: 4 }
                    width: Layout.preferredWidth
                    style: parent.modelData.s
                    showTemperature: true
                }
            }
        }
    }
}

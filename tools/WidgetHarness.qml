/*
    Standalone host for the widget views, for previewing them outside
    plasmashell:  make widget-preview

    Shows the panel view at several panel heights and styles, in a vertical
    panel, the full view, and both views for a GPU index that does not exist.
    Live data comes from ksystemstats like in the real widget.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../package/contents/ui" as Widget

QQC2.ApplicationWindow {
    id: harness
    title: "WidgetHarness"
    width: 900
    height: 760
    visible: true
    color: Kirigami.Theme.backgroundColor

    function i18n(s, a, b, c) { return s.replace("%1", a ?? "").replace("%2", b ?? "").replace("%3", c ?? "") }
    function i18np(s, p, n) { return (n === 1 ? s : p).replace("%1", n) }
    function i18nc(ctx, s, a, b) { return i18n(s, a, b) }

    Widget.GpuSensors { id: gpu; gpuId: "gpu/gpu0"; powerFallbackEnabled: true }
    Widget.GpuSensors { id: missingGpu; gpuId: "gpu/gpu7" }

    component PanelStrip: Rectangle {
        id: strip
        property int panelHeight: 32
        property int style: 0
        property bool temp: true
        property Widget.GpuSensors sensors: gpu
        color: Qt.darker(Kirigami.Theme.backgroundColor, 1.3)
        implicitHeight: panelHeight
        implicitWidth: compact.Layout.preferredWidth + 8
        Widget.CompactRepresentation {
            id: compact
            gpu: strip.sensors
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left; leftMargin: 4 }
            width: Layout.preferredWidth
            style: strip.style
            showTemperature: strip.temp
        }
    }

    GridLayout {
        anchors { fill: parent; margins: 12 }
        columns: 2
        columnSpacing: 16
        rowSpacing: 8

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 6
            QQC2.Label { text: "Horizontal panels, 24 / 32 / 40 px, style 0" }
            PanelStrip { panelHeight: 24 }
            PanelStrip { panelHeight: 32 }
            PanelStrip { panelHeight: 40 }
            QQC2.Label { text: "32 px, styles 1 / 2 / 3" }
            PanelStrip { panelHeight: 32; style: 1 }
            PanelStrip { panelHeight: 32; style: 2 }
            PanelStrip { panelHeight: 32; style: 3 }
            QQC2.Label { text: "No GPU (index 7): 32 px panel" }
            PanelStrip { panelHeight: 32; sensors: missingGpu }
            QQC2.Label { text: "Vertical panel, 56 px wide" }
            Rectangle {
                color: Qt.darker(Kirigami.Theme.backgroundColor, 1.3)
                implicitWidth: 56
                implicitHeight: vcompact.Layout.minimumHeight + 8
                Widget.CompactRepresentation {
                    id: vcompact
                    gpu: gpu
                    anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 4 }
                    height: Layout.minimumHeight
                    vertical: true
                }
            }
            QQC2.Label {
                Layout.topMargin: 8
                text: "Power fallback: " + (gpu.powerAvailable ? gpu.powerText : "n/a")
            }
            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 6
            QQC2.Label { text: "Full view" }
            Rectangle {
                color: Qt.darker(Kirigami.Theme.backgroundColor, 1.15)
                Layout.preferredWidth: 380
                Layout.preferredHeight: 300
                Widget.FullRepresentation { anchors.fill: parent; gpu: gpu; showPower: gpu.powerAvailable }
            }
            QQC2.Label { text: "Full view, no GPU (index 7)" }
            Rectangle {
                color: Qt.darker(Kirigami.Theme.backgroundColor, 1.15)
                Layout.preferredWidth: 380
                Layout.preferredHeight: 120
                Widget.FullRepresentation { anchors.fill: parent; gpu: missingGpu; gpuIndex: 7 }
            }
            Item { Layout.fillHeight: true }
        }
    }
}

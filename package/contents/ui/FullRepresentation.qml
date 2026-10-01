/*
    Desktop view / popup: name, bars with numbers, temperature and power,
    and a history graph of usage and VRAM percent.

    Configuration is passed in as plain properties (no Plasmoid attached
    object) so the view can be previewed outside plasmashell.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartsControls

Item {
    id: root

    required property GpuSensors gpu
    property int gpuIndex: 0
    property int updateInterval: 1000
    property int historySeconds: 60
    property bool showHistory: true
    property bool showPower: false
    property bool customColors: false
    property string customUsageColor: ""
    property string customVramColor: ""
    readonly property color usageColor: customColors && customUsageColor ? customUsageColor : Kirigami.Theme.highlightColor
    readonly property color vramColor: customColors && customVramColor ? customVramColor : Kirigami.Theme.positiveTextColor
    readonly property bool historyVisible: showHistory && gpu.available
    readonly property int historyPoints: Math.max(2, Math.round(historySeconds * 1000 / Math.max(250, updateInterval)))

    Layout.minimumWidth: Kirigami.Units.gridUnit * 14
    Layout.minimumHeight: historyVisible ? Kirigami.Units.gridUnit * 10 : Kirigami.Units.gridUnit * 6
    Layout.preferredWidth: Kirigami.Units.gridUnit * 18
    Layout.preferredHeight: historyVisible ? Kirigami.Units.gridUnit * 13 : Kirigami.Units.gridUnit * 6

    // A change of sampling interval or length would leave stale points in the
    // buffer; start over instead.
    onUpdateIntervalChanged: clearHistory()
    onHistorySecondsChanged: clearHistory()

    function clearHistory() {
        usageHistory.clear()
        vramHistory.clear()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: Qt.resolvedUrl("../icons/amdgpumonitor.svg")
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                elide: Text.ElideRight
                text: root.gpu.displayName
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            visible: !root.gpu.available
            wrapMode: Text.WordWrap
            text: root.gpuIndex < 0
                ? i18n("The Plasma system statistics daemon (ksystemstats) reports no GPU. Check that its GPU plugin is installed and the GPU driver is loaded.")
                : i18n("No GPU sensors found for ksystemstats index %1. Pick another GPU in the widget settings.", root.gpuIndex)
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.gpu.available
            columns: 3
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label { text: i18n("Usage") }
            UsageBar {
                Layout.fillWidth: true
                value: root.gpu.usagePercent
                color: root.usageColor
                Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
            }
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                text: root.gpu.usageAvailable ? i18n("%1%", root.gpu.usagePercent.toFixed(0)) : i18n("n/a")
            }

            PlasmaComponents.Label { text: i18n("VRAM") }
            UsageBar {
                Layout.fillWidth: true
                value: root.gpu.vramPercent
                color: root.vramColor
                Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
            }
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                text: root.gpu.vramTotalBytes > 0
                    ? i18n("%1 / %2", root.gpu.formatGiB(root.gpu.vramUsedBytes), root.gpu.formatGiB(root.gpu.vramTotalBytes))
                    : i18n("n/a")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.gpu.available
            spacing: Kirigami.Units.largeSpacing

            PlasmaComponents.Label {
                visible: root.gpu.temperatureAvailable
                opacity: 0.8
                text: i18n("Temp: %1", root.gpu.temperature.formattedValue)
            }
            PlasmaComponents.Label {
                visible: root.showPower
                opacity: 0.8
                text: i18n("Power: %1", root.gpu.powerText)
            }
            Item { Layout.fillWidth: true }
        }

        // Legend: colour swatch, name and current value per series
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            visible: root.historyVisible
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: [
                    { name: i18n("Usage"), color: root.usageColor },
                    { name: i18n("VRAM"), color: root.vramColor }
                ]
                delegate: RowLayout {
                    id: legendEntry
                    required property var modelData
                    required property int index
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        implicitWidth: Kirigami.Units.smallSpacing * 2
                        implicitHeight: implicitWidth
                        radius: 2
                        color: legendEntry.modelData.color
                    }
                    PlasmaComponents.Label {
                        font: Kirigami.Theme.smallFont
                        text: legendEntry.modelData.name
                    }
                    PlasmaComponents.Label {
                        font: Kirigami.Theme.smallFont
                        opacity: 0.8
                        text: legendEntry.index === 0
                            ? i18n("%1%", root.gpu.usagePercent.toFixed(0))
                            : i18n("%1%", root.gpu.vramPercent.toFixed(0))
                    }
                }
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.Label {
                font: Kirigami.Theme.smallFont
                opacity: 0.6
                text: i18n("last %1 s", root.historySeconds)
            }
        }

        // History graph: usage % and VRAM % (of total), newest sample at the right edge
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 3
            visible: root.historyVisible

            Rectangle {
                anchors.fill: parent
                color: Kirigami.Theme.textColor
                opacity: 0.06
                radius: Kirigami.Units.cornerRadius
            }

            ChartsControls.GridLines {
                anchors.fill: chart
                chart: chart
                direction: ChartsControls.GridLines.Vertical   // "Vertical" lays lines out along the Y axis, i.e. horizontal lines
                major.visible: false
                minor.count: 3          // lines at 25 %, 50 %, 75 %
                minor.lineWidth: 1
                minor.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
            }

            Charts.LineChart {
                id: chart
                anchors.fill: parent
                anchors.margins: 1

                smooth: true
                lineWidth: 2
                fillOpacity: 0.25
                // Index 0 (newest sample) is drawn at the right edge; missing
                // history is padded at the old end, so the graph scrolls in from the right.
                direction: Charts.XYChart.ZeroAtEnd
                yRange { from: 0; to: 100; automatic: false }

                colorSource: Charts.ArraySource { array: [root.usageColor, root.vramColor] }
                nameSource: Charts.ArraySource { array: [i18n("Usage"), i18n("VRAM")] }

                valueSources: [
                    Charts.HistoryProxySource {
                        id: usageHistory
                        source: Charts.SingleValueSource { value: root.gpu.usagePercent }
                        interval: root.updateInterval
                        maximumHistory: root.historyPoints
                        fillMode: Charts.HistoryProxySource.FillFromStart
                    },
                    Charts.HistoryProxySource {
                        id: vramHistory
                        source: Charts.SingleValueSource { value: root.gpu.vramPercent }
                        interval: root.updateInterval
                        maximumHistory: root.historyPoints
                        fillMode: Charts.HistoryProxySource.FillFromStart
                    }
                ]
            }

            PlasmaComponents.Label {
                anchors { left: parent.left; top: parent.top; margins: Kirigami.Units.smallSpacing }
                font: Kirigami.Theme.smallFont
                opacity: 0.5
                text: "100%"
            }
            PlasmaComponents.Label {
                anchors { left: parent.left; bottom: parent.bottom; margins: Kirigami.Units.smallSpacing }
                font: Kirigami.Theme.smallFont
                opacity: 0.5
                text: "0%"
            }
        }
    }
}

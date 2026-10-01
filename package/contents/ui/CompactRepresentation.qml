/*
    Panel view: one row per metric (GPU usage, VRAM, temperature).

    Styles (config compactStyle):
      0  labels + bars + values
      1  bars only
      2  labels + values (text only)
      3  labels + bars (no values)

    Rows share the available panel height minus a configurable top/bottom
    margin, so the widget stays compact on thin panels. All configuration
    arrives as plain properties so the view can be previewed outside
    plasmashell (tools/WidgetHarness.qml).

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

MouseArea {
    id: root

    required property GpuSensors gpu
    property bool vertical: false
    property int style: 0
    property int verticalMargin: 2
    property bool showUsage: true
    property bool showVram: true
    property bool showTemperature: false
    property bool vramAsPercent: false
    property bool customColors: false
    property string customUsageColor: ""
    property string customVramColor: ""
    property string customTemperatureColor: ""

    signal activated()

    readonly property bool showLabels: !vertical && style !== 1
    readonly property bool showBars: style !== 2
    readonly property bool showValues: style === 0 || style === 2
    readonly property int rowSpacing: 1

    // Static list of row keys; values are looked up per delegate so a sensor
    // update does not rebuild the rows.
    readonly property var rows: {
        let r = []
        if (showUsage) r.push("usage")
        if (showVram) r.push("vram")
        if (showTemperature) r.push("temp")
        return r
    }
    readonly property int rowCount: Math.max(1, rows.length)

    // Height of one row: in horizontal panels fill the widget height minus
    // margins; in vertical panels a row is a bar stacked above its value.
    readonly property int verticalBarHeight: 4
    readonly property real rowHeight: vertical
        ? (showBars ? verticalBarHeight + 2 : 0) + (showValues ? smallMetrics.height : 0)
        : Math.max(5, (height - 2 * verticalMargin - rowSpacing * (rowCount - 1)) / rowCount)

    readonly property font rowFont: Qt.font({
        family: Kirigami.Theme.smallFont.family,
        pixelSize: Math.max(7, Math.min(Math.round(rowHeight * 0.9), Math.round(smallMetrics.height * 0.85)))
    })

    function labelFor(key) {
        switch (key) {
        case "usage": return i18nc("short label for GPU usage", "GPU")
        case "vram":  return i18nc("short label for video memory", "VRAM")
        case "temp":  return i18nc("short label for temperature in degrees Celsius", "°C")
        }
        return ""
    }

    // Bar fill in percent. Temperature maps degrees Celsius 1:1 to percent.
    function percentFor(key) {
        switch (key) {
        case "usage": return gpu.usagePercent
        case "vram":  return gpu.vramPercent
        case "temp":  return gpu.temperatureCelsius
        }
        return 0
    }

    function textFor(key) {
        switch (key) {
        case "usage":
            return gpu.usageAvailable ? gpu.usagePercent.toFixed(0) + "%" : i18nc("value not available", "n/a")
        case "vram":
            if (!gpu.vramAvailable) return i18nc("value not available", "n/a")
            return vramAsPercent ? gpu.vramPercent.toFixed(0) + "%" : gpu.formatGiB(gpu.vramUsedBytes)
        case "temp":
            return gpu.temperatureAvailable ? gpu.temperatureCelsius.toFixed(0) + "°" : i18nc("value not available", "n/a")
        }
        return ""
    }

    // Resolved in a function, not as colour properties on this root item:
    // `property color x: Kirigami.Theme.<colour>` declarations on the applet or
    // compact root crashed plasmashell at startup (Kirigami's Plasma style syncs
    // colours while the shell reparents the item). Functions read the theme the
    // same way the first working version did.
    function colorFor(key) {
        switch (key) {
        case "usage": return customColors && customUsageColor ? customUsageColor : Kirigami.Theme.highlightColor
        case "vram":  return customColors && customVramColor ? customVramColor : Kirigami.Theme.positiveTextColor
        case "temp":  return customColors && customTemperatureColor ? customTemperatureColor : Kirigami.Theme.neutralTextColor
        }
        return Kirigami.Theme.textColor
    }

    Layout.minimumWidth: vertical ? Kirigami.Units.iconSizes.small : (gpu.available ? column.implicitWidth : unavailableLabel.implicitWidth)
    Layout.preferredWidth: vertical ? -1 : Layout.minimumWidth
    Layout.minimumHeight: vertical ? (gpu.available ? column.implicitHeight : unavailableLabel.implicitHeight) + 2 * verticalMargin : Kirigami.Units.iconSizes.small

    hoverEnabled: true
    onClicked: root.activated()

    FontMetrics {
        id: smallMetrics
        font: Kirigami.Theme.smallFont
    }
    TextMetrics {
        id: labelMetrics
        font: root.rowFont
        text: "VRAM"
    }
    TextMetrics {
        id: valueMetrics
        font: root.rowFont
        text: root.vramAsPercent ? "100%" : "00.0 GiB"
    }

    // Shown instead of the rows when ksystemstats reports nothing for this GPU
    // (wrong index, no GPU plugin, GPU not yet present). The tooltip explains.
    Text {
        id: unavailableLabel
        anchors.centerIn: parent
        visible: !root.gpu.available
        text: i18nc("shown in the panel when no GPU data is available", "GPU n/a")
        font: Kirigami.Theme.smallFont
        color: Kirigami.Theme.textColor
        opacity: 0.6
    }

    ColumnLayout {
        id: column
        visible: root.gpu.available
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            topMargin: root.verticalMargin
            bottomMargin: root.verticalMargin
        }
        spacing: root.rowSpacing

        Repeater {
            model: root.rows

            // Horizontal panel: label | bar | value in one line.
            // Vertical panel: bar above value (no label, too narrow).
            delegate: GridLayout {
                id: row
                required property string modelData
                readonly property string key: modelData

                columns: root.vertical ? 1 : 3
                Layout.fillWidth: true
                Layout.fillHeight: !root.vertical
                Layout.preferredHeight: root.rowHeight
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: 2

                Text {
                    visible: root.showLabels
                    text: root.labelFor(row.key)
                    font: root.rowFont
                    color: Kirigami.Theme.textColor
                    opacity: 0.7
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillHeight: true
                    Layout.preferredWidth: labelMetrics.width
                }

                UsageBar {
                    visible: root.showBars
                    value: root.percentFor(row.key)
                    color: root.colorFor(row.key)
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: root.vertical ? 0 : Kirigami.Units.gridUnit * 2.5
                    Layout.preferredHeight: root.vertical ? root.verticalBarHeight : Math.max(2, Math.round(root.rowHeight * 0.5))
                }

                Text {
                    visible: root.showValues
                    text: root.textFor(row.key)
                    font: root.rowFont
                    color: Kirigami.Theme.textColor
                    horizontalAlignment: root.vertical ? Text.AlignHCenter : Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    Layout.fillHeight: !root.vertical
                    Layout.fillWidth: root.vertical
                    Layout.preferredWidth: root.vertical ? -1 : valueMetrics.width
                }
            }
        }
    }
}

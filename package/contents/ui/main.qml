/*
    AMD GPU Monitor – Plasma 6 widget root.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    readonly property GpuSensors gpu: GpuSensors {
        // index -1 selects the ksystemstats aggregate over all GPUs
        gpuId: Plasmoid.configuration.gpuIndex < 0 ? "gpu/all" : "gpu/gpu" + Plasmoid.configuration.gpuIndex
        updateRateLimit: Plasmoid.configuration.updateInterval
        powerFallbackEnabled: Plasmoid.configuration.showPower && Plasmoid.configuration.powerFallback
        powerSysfsPath: Plasmoid.configuration.powerSysfsPath
    }

    // Series colours are resolved inside the representations (theme colours unless
    // custom ones are configured). Keep Kirigami.Theme off this root item: the
    // Plasma Kirigami style syncs theme colours while the shell reparents the
    // applet item, and bindings here crashed plasmashell at startup.
    readonly property bool customColors: Plasmoid.configuration.useCustomColors
    readonly property string customUsageColor: Plasmoid.configuration.usageColor
    readonly property string customVramColor: Plasmoid.configuration.vramColor
    readonly property string customTemperatureColor: Plasmoid.configuration.temperatureColor
    readonly property bool powerVisible: Plasmoid.configuration.showPower && gpu.powerAvailable

    // Desktop: always the full view. Panels: let Plasma pick the compact view;
    // clicking it opens the full view as a popup (same as the stock System Monitor applets).
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : null

    compactRepresentation: CompactRepresentation {
        gpu: root.gpu
        vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        style: Plasmoid.configuration.compactStyle
        verticalMargin: Plasmoid.configuration.verticalMargin
        showUsage: Plasmoid.configuration.showUsage
        showVram: Plasmoid.configuration.showVram
        showTemperature: Plasmoid.configuration.showTemperature
        vramAsPercent: Plasmoid.configuration.vramAsPercent
        onActivated: root.expanded = !root.expanded
        customColors: root.customColors
        customUsageColor: root.customUsageColor
        customVramColor: root.customVramColor
        customTemperatureColor: root.customTemperatureColor
    }

    fullRepresentation: FullRepresentation {
        gpu: root.gpu
        gpuIndex: Plasmoid.configuration.gpuIndex
        updateInterval: Plasmoid.configuration.updateInterval
        historySeconds: Plasmoid.configuration.historySeconds
        showHistory: Plasmoid.configuration.showHistory
        showPower: root.powerVisible
        customColors: root.customColors
        customUsageColor: root.customUsageColor
        customVramColor: root.customVramColor
    }

    // Own icon for the tooltip and the icon-only compact mode. The widget explorer
    // resolves metadata.json "Icon" through the icon theme only, so that one stays
    // a Breeze name (ksysguardd); the store listing uses store/icon.svg.
    Plasmoid.icon: "ksysguardd"

    toolTipMainText: gpu.displayName
    toolTipSubText: {
        if (!gpu.available) {
            return Plasmoid.configuration.gpuIndex < 0
                ? i18n("No GPU sensors found (ksystemstats reports no GPU)")
                : i18n("No GPU sensors found (ksystemstats index %1). Pick another GPU in the settings.", Plasmoid.configuration.gpuIndex)
        }
        let lines = []
        lines.push(i18n("Usage: %1%", gpu.usagePercent.toFixed(0)))
        lines.push(i18n("VRAM: %1 / %2 (%3%)", gpu.formatGiB(gpu.vramUsedBytes), gpu.formatGiB(gpu.vramTotalBytes), gpu.vramPercent.toFixed(0)))
        if (gpu.temperatureAvailable) {
            lines.push(i18n("Temperature: %1", gpu.temperature.formattedValue))
        }
        if (powerVisible) {
            lines.push(i18n("Power: %1", gpu.powerText))
        }
        return lines.join("\n")
    }
}

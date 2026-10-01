/*
    Wraps the ksystemstats sensors of one GPU (gpu/gpu<N>/... or gpu/all/...)
    and derives convenient numeric values for the views.

    Optionally reads the board power from sysfs (hwmon power1_average) when
    ksystemstats does not deliver a power value; some AMD cards expose only
    power1_average, which the ksystemstats GPU plugin does not read.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as P5Support

QtObject {
    id: root

    // ksystemstats id prefix, e.g. "gpu/gpu0" or "gpu/all"
    property string gpuId: "gpu/gpu0"
    // milliseconds between value updates
    property int updateRateLimit: 1000
    // sysfs power fallback (opt-in); empty path means "first amdgpu hwmon found"
    property bool powerFallbackEnabled: false
    property string powerSysfsPath: ""

    readonly property bool aggregate: gpuId === "gpu/all"

    readonly property Sensors.Sensor name: Sensors.Sensor {
        sensorId: root.aggregate ? "" : root.gpuId + "/name"
        updateRateLimit: root.updateRateLimit
    }
    readonly property Sensors.Sensor usage: Sensors.Sensor {
        sensorId: root.gpuId + "/usage"
        updateRateLimit: root.updateRateLimit
    }
    readonly property Sensors.Sensor usedVram: Sensors.Sensor {
        sensorId: root.gpuId + "/usedVram"
        updateRateLimit: root.updateRateLimit
    }
    readonly property Sensors.Sensor totalVram: Sensors.Sensor {
        sensorId: root.gpuId + "/totalVram"
        updateRateLimit: root.updateRateLimit
    }
    readonly property Sensors.Sensor temperature: Sensors.Sensor {
        sensorId: root.aggregate ? "" : root.gpuId + "/temperature"
        updateRateLimit: root.updateRateLimit
    }
    readonly property Sensors.Sensor power: Sensors.Sensor {
        sensorId: root.aggregate ? "" : root.gpuId + "/power"
        updateRateLimit: root.updateRateLimit
    }

    // ---- derived values (Sensor.value is a QVariant; coerce and guard) ----
    function isNumber(v) { return v !== undefined && v !== null && !isNaN(Number(v)) }

    readonly property bool usageAvailable: isNumber(usage.value)
    readonly property bool vramAvailable: vramTotalBytes > 0
    readonly property bool temperatureAvailable: isNumber(temperature.value)
    readonly property bool available: vramAvailable || usageAvailable

    readonly property real usagePercent: usageAvailable ? Math.max(0, Math.min(100, Number(usage.value))) : 0
    readonly property real vramUsedBytes: Number(usedVram.value) || 0
    readonly property real vramTotalBytes: Number(totalVram.value) || 0
    readonly property real vramPercent: vramTotalBytes > 0 ? vramUsedBytes / vramTotalBytes * 100 : 0
    readonly property real temperatureCelsius: temperatureAvailable ? Number(temperature.value) : 0

    readonly property string displayName: aggregate
        ? i18n("All GPUs")
        : ((name.value !== undefined && String(name.value).length > 0) ? String(name.value) : i18n("GPU"))

    // ---- power: ksystemstats first, sysfs fallback second ----
    readonly property bool sensorPowerAvailable: isNumber(power.value) && Number(power.value) > 0
    property real fallbackPowerWatts: NaN
    readonly property bool powerAvailable: sensorPowerAvailable || !isNaN(fallbackPowerWatts)
    readonly property real powerWatts: sensorPowerAvailable ? Number(power.value) : fallbackPowerWatts
    readonly property string powerText: sensorPowerAvailable
        ? power.formattedValue
        : (isNaN(fallbackPowerWatts) ? "" : i18nc("watts", "%1 W", fallbackPowerWatts.toFixed(0)))

    readonly property string powerCommand: {
        if (powerSysfsPath.length > 0) {
            return "cat '" + powerSysfsPath.replace(/'/g, "'\\''") + "'"
        }
        return "sh -c 'for f in /sys/class/drm/card*/device/hwmon/hwmon*/power1_average /sys/class/drm/card*/device/hwmon/hwmon*/power1_input; do [ -r \"$f\" ] && { cat \"$f\"; exit 0; }; done; exit 1'"
    }
    readonly property bool useFallback: powerFallbackEnabled && !aggregate && !sensorPowerAvailable

    readonly property P5Support.DataSource powerSource: P5Support.DataSource {
        engine: "executable"
        interval: Math.max(1000, root.updateRateLimit)
        connectedSources: root.useFallback ? [root.powerCommand] : []
        onNewData: (source, data) => {
            const uw = parseInt(String(data["stdout"]).trim())
            root.fallbackPowerWatts = (data["exit code"] === 0 && !isNaN(uw)) ? uw / 1e6 : NaN
        }
    }
    onUseFallbackChanged: if (!useFallback) fallbackPowerWatts = NaN

    function formatGiB(bytes, decimals) {
        const d = decimals === undefined ? 1 : decimals
        return (bytes / 1073741824).toFixed(d) + " GiB"
    }
}

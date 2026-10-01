/*
    Settings page.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

import ".." as Widget

KCM.SimpleKCM {
    id: root

    property int cfg_gpuIndex
    property alias cfg_updateInterval: intervalSpin.value
    property alias cfg_showUsage: showUsageCheck.checked
    property alias cfg_showVram: showVramCheck.checked
    property alias cfg_showTemperature: showTemperatureCheck.checked
    property alias cfg_showPower: showPowerCheck.checked
    property alias cfg_powerFallback: powerFallbackCheck.checked
    property alias cfg_powerSysfsPath: powerPathField.text
    property alias cfg_compactStyle: compactStyleCombo.currentIndex
    property alias cfg_verticalMargin: marginSpin.value
    property alias cfg_vramAsPercent: vramPercentCheck.checked
    property alias cfg_useCustomColors: customColorsCheck.checked
    property alias cfg_usageColor: usageColorButton.colorString
    property alias cfg_vramColor: vramColorButton.colorString
    property alias cfg_temperatureColor: temperatureColorButton.colorString
    property alias cfg_showHistory: showHistoryCheck.checked
    property alias cfg_historySeconds: historySpin.value

    // Plasma 6.7 panels add "expanding" and "length" to every panel applet's
    // configuration; declaring them avoids "does not have a property" warnings.
    property bool cfg_expanding
    property int cfg_length

    // *Default properties let the dialog offer "Defaults"
    property int cfg_gpuIndexDefault: 0
    property int cfg_updateIntervalDefault: 1000
    property bool cfg_showUsageDefault: true
    property bool cfg_showVramDefault: true
    property bool cfg_showTemperatureDefault: false
    property bool cfg_showPowerDefault: false
    property bool cfg_powerFallbackDefault: false
    property string cfg_powerSysfsPathDefault: ""
    property int cfg_compactStyleDefault: 0
    property int cfg_verticalMarginDefault: 2
    property bool cfg_vramAsPercentDefault: false
    property bool cfg_useCustomColorsDefault: false
    property string cfg_usageColorDefault: "#3daee9"
    property string cfg_vramColorDefault: "#27ae60"
    property string cfg_temperatureColorDefault: "#f67400"
    property bool cfg_showHistoryDefault: true

    // Small wrapper so a colour can be stored as a string config entry.
    component ColorEntry: KQuickControls.ColorButton {
        property string colorString: color.toString()
        onColorStringChanged: if (color.toString() !== colorString) color = colorString
        onColorChanged: colorString = color.toString()
        showAlphaChannel: false
    }

    Widget.GpuProbe {
        id: gpuProbe
        onGpusChanged: gpuCombo.syncFromConfig()
    }
    onCfg_gpuIndexChanged: gpuCombo.syncFromConfig()
    property int cfg_historySecondsDefault: 60

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Data source")
        }

        QQC2.ComboBox {
            id: gpuCombo
            Kirigami.FormData.label: i18n("GPU:")
            Layout.minimumWidth: Kirigami.Units.gridUnit * 18
            textRole: "text"
            valueRole: "index"

            // Detected GPUs, plus the configured index if it is not (yet) detected.
            model: {
                let entries = gpuProbe.gpus.map(g => ({ index: g.index, text: i18n("%1 (gpu%2)", g.name, g.index) }))
                if (gpuProbe.gpus.length > 1) {
                    entries.push({ index: -1, text: i18n("All GPUs combined") })
                }
                if (!entries.some(e => e.index === root.cfg_gpuIndex)) {
                    entries.push({ index: root.cfg_gpuIndex, text: root.cfg_gpuIndex < 0 ? i18n("All GPUs combined") : i18n("gpu%1 (not detected)", root.cfg_gpuIndex) })
                }
                return entries
            }
            onModelChanged: syncFromConfig()
            onActivated: root.cfg_gpuIndex = currentValue

            function syncFromConfig() {
                const i = indexOfValue(root.cfg_gpuIndex)
                if (i >= 0 && i !== currentIndex) currentIndex = i
            }
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: gpuProbe.gpus.length > 0
                ? i18np("One GPU reported by the Plasma system statistics daemon.", "%1 GPUs reported by the Plasma system statistics daemon.", gpuProbe.gpus.length)
                : i18n("No GPU reported by the Plasma system statistics daemon (ksystemstats). Check that its GPU plugin is installed.")
        }

        QQC2.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: i18n("Update interval:")
            from: 250
            to: 10000
            stepSize: 250
            textFromValue: (value, locale) => i18n("%1 ms", value)
            valueFromText: (text, locale) => parseInt(text)
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel view")
        }

        QQC2.ComboBox {
            id: compactStyleCombo
            Kirigami.FormData.label: i18n("Style:")
            model: [i18n("Labels, bars and values"), i18n("Bars only"), i18n("Labels and values"), i18n("Labels and bars")]
        }

        QQC2.SpinBox {
            id: marginSpin
            Kirigami.FormData.label: i18n("Vertical margin:")
            from: 0
            to: 12
            textFromValue: (value, locale) => i18n("%1 px", value)
            valueFromText: (text, locale) => parseInt(text)
        }

        QQC2.CheckBox {
            id: showUsageCheck
            Kirigami.FormData.label: i18n("Show:")
            text: i18n("GPU usage")
        }
        QQC2.CheckBox {
            id: showVramCheck
            text: i18n("VRAM usage")
        }
        QQC2.CheckBox {
            id: showTemperatureCheck
            text: i18n("Temperature")
        }
        QQC2.CheckBox {
            id: showPowerCheck
            text: i18n("Power (tooltip and full view)")
        }
        QQC2.CheckBox {
            id: powerFallbackCheck
            enabled: showPowerCheck.checked
            Layout.leftMargin: Kirigami.Units.gridUnit
            text: i18n("Read power from sysfs if ksystemstats has none")
        }
        QQC2.TextField {
            id: powerPathField
            enabled: showPowerCheck.checked && powerFallbackCheck.checked
            Kirigami.FormData.label: i18n("hwmon file:")
            Layout.minimumWidth: Kirigami.Units.gridUnit * 18
            placeholderText: i18n("auto (first amdgpu power1_average)")
        }
        QQC2.CheckBox {
            id: vramPercentCheck
            text: i18n("Show VRAM as percent instead of GiB")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Colours")
        }

        QQC2.CheckBox {
            id: customColorsCheck
            text: i18n("Use custom colours instead of the theme's")
        }
        ColorEntry {
            id: usageColorButton
            Kirigami.FormData.label: i18n("GPU usage:")
            enabled: customColorsCheck.checked
            dialogTitle: i18n("GPU usage colour")
        }
        ColorEntry {
            id: vramColorButton
            Kirigami.FormData.label: i18n("VRAM:")
            enabled: customColorsCheck.checked
            dialogTitle: i18n("VRAM colour")
        }
        ColorEntry {
            id: temperatureColorButton
            Kirigami.FormData.label: i18n("Temperature:")
            enabled: customColorsCheck.checked
            dialogTitle: i18n("Temperature colour")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Full view")
        }

        QQC2.CheckBox {
            id: showHistoryCheck
            Kirigami.FormData.label: i18n("History graph:")
            text: i18n("Show usage and VRAM history")
        }

        QQC2.SpinBox {
            id: historySpin
            Kirigami.FormData.label: i18n("History length:")
            enabled: showHistoryCheck.checked
            from: 10
            to: 600
            stepSize: 10
            textFromValue: (value, locale) => i18n("%1 s", value)
            valueFromText: (text, locale) => parseInt(text)
        }
    }
}

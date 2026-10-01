/*
    Detects the GPUs known to ksystemstats by probing gpu/gpu<N>/name for the
    first few indices. Exposes a list of { index, name } for the ones that
    answer.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
pragma ComponentBehavior: Bound
import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root
    visible: false

    property int maxIndex: 8
    // [{ index: 0, name: "Navi 32 [...]" }, ...]
    property var gpus: []

    function refresh() {
        let result = []
        for (let i = 0; i < probes.count; ++i) {
            const s = probes.objectAt(i) as Sensors.Sensor
            if (s && s.value !== undefined && s.value !== null && String(s.value).length > 0) {
                result.push({ index: i, name: String(s.value) })
            }
        }
        gpus = result
    }

    Instantiator {
        id: probes
        model: root.maxIndex
        delegate: Sensors.Sensor {
            required property int index
            sensorId: "gpu/gpu" + index + "/name"
            updateRateLimit: 5000
            onValueChanged: root.refresh()
        }
    }
}

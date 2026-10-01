/*
    Thin horizontal bar, 0..100 percent.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property real value: 0            // 0..100
    property color color: Kirigami.Theme.highlightColor
    property real radius: height / 2

    implicitHeight: Kirigami.Units.smallSpacing
    implicitWidth: Kirigami.Units.gridUnit * 4

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Kirigami.Theme.textColor
        opacity: 0.18
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: root.radius
        color: root.color
        width: Math.max(0, Math.min(1, root.value / 100)) * parent.width

        Behavior on width {
            NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
        }
    }
}

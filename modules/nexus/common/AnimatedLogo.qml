import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services

Item {
    id: root

    property real blurAmount: skipIntroAnimation ? 0.0 : 1.0
    property bool skipIntroAnimation: false
    signal animationCompleted

    implicitWidth: 128
    implicitHeight: 90.38

    Image {
        id: logo

        anchors.centerIn: parent
        source: Qt.resolvedUrl("../../../assets/logo.svg")
        width: 128
        height: 90.38
        fillMode: Image.PreserveAspectFit
        transformOrigin: Item.Center
        scale: root.skipIntroAnimation ? 1 : 0
        opacity: root.skipIntroAnimation ? 1 : 0

        layer.enabled: root.blurAmount > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 60
        }
    }

    SequentialAnimation {
        running: !root.skipIntroAnimation
        onFinished: root.animationCompleted()

        ParallelAnimation {
            NumberAnimation {
                target: logo
                property: "scale"
                from: 0
                to: 1.08
                duration: 1000
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: logo
                property: "opacity"
                from: 0
                to: 1
                duration: 600
            }
            NumberAnimation {
                target: root
                property: "blurAmount"
                from: 1
                to: 0
                duration: 900
                easing.type: Easing.OutCubic
            }
        }
        NumberAnimation {
            target: logo
            property: "scale"
            to: 1
            duration: 250
            easing.type: Easing.OutBack
        }
    }
}

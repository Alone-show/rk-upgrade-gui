import QtQuick 2.15
import QtQuick.Controls 2.15
import App 1.0

Button {
    id: control

    implicitWidth: 80
    implicitHeight: 25

    background: Rectangle {
        color: !control.enabled ? "#C4C4C4"               // 禁用灰
              : control.down ? "#D0D0D0" : "#E1E1E1"     // 按下/正常
        border.color: "#ADADAD"
        border.width: 1
        radius: 3
    }

    contentItem: Text {
        text: control.text
        font.pixelSize: 13
        color: control.enabled ? "black" : "#808080"      // 禁用文字变灰
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    onClicked: {
        // console.debug("按钮被点了")
        AppState.allButtonEnabled = false
    }

    enabled: AppState.allButtonEnabled
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt.labs.settings 1.0 // 用于记忆功能
Rectangle {
    id: root

    // 外部接口
    property string cellText: ""
    property int textAlign: Text.AlignHCenter
    property bool isReadOnly: false

    // 信号：编辑完成传回数据
    signal commit(string newText)

    // 内部状态
    property bool isEditing: false

    color: isEditing ? "#FFFFFF" : "transparent"
    border.color: isEditing ? "#0078D7" : "transparent"
    border.width: isEditing ? 1 : 0
    clip: true


    Settings {
        id: settingPath
        category: "edieSetting"

        // 记忆显示的路径 (清洗后的字符串，如 C:\Download\xxx.img)
        property string savedFirmwarePath: "file:///"

    }

    CustomFileDialog {
        id: myFileDialog
        // 设置起始路径 (例如 file:///C:/)
        currentFolder: settingPath.savedFirmwarePath
        // 过滤器
        nameFilters: ["*.img", "*.bin"]

        // 处理选中信号
        onFileSelected: (filePath) => {
            console.log("用户选择了文件: " + filePath)
            settingPath.savedFirmwarePath = parentUrl("file://" + filePath)
            // firmPathText.text = filePath
            root.commit(filePath)
        }

        onCancel: {

        }
    }

    // 1. 显示文本
    Text {
        visible: !root.isEditing
        text: root.cellText
        anchors.fill: parent
        anchors.leftMargin: root.textAlign === Text.AlignLeft ? 5 : 0
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: root.textAlign
        font.pixelSize: 12
        elide: Text.ElideRight
        color: "black"
    }

    // 2. 编辑输入框
    TextInput {
        id: inputField
        visible: root.isEditing
        text: root.cellText
        anchors.fill: parent
        anchors.leftMargin: root.textAlign === Text.AlignLeft ? 5 : 0
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: root.textAlign
        font.pixelSize: 12
        selectByMouse: true
        selectionColor: "#0078D7"
        color: "black"

        onEditingFinished: root.finishEdit()
        onActiveFocusChanged: {
            if (!activeFocus && root.isEditing) root.finishEdit()
        }
    }

    // 3. 鼠标交互
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton     // 必须加
        propagateComposedEvents: true      // 防止父级挡住

        // 单击逻辑
        onClicked: {
            // 延迟判断是否为双击
            if (isReadOnly)
                return
            clickTimer.restart()
        }

        // 双击逻辑
        onDoubleClicked: {
            if (isReadOnly)
                return
            clickTimer.stop()              // 阻止单击逻辑
            console.log("Double Click OK")
            myFileDialog.open()
        }

        Timer {
            id: clickTimer
            interval: 200
            repeat: false
            onTriggered: {
                // 只在真正的单击时执行
                root.isEditing = true
                inputField.forceActiveFocus()
                inputField.selectAll()
            }
        }
    }


    function finishEdit() {
        if (root.isEditing) {
            root.isEditing = false
            if (inputField.text !== root.cellText) {
                root.commit(inputField.text)
            }
        }
    }

    function parentUrl(url) {
        // 移除末尾文件名部分
        var idx = url.lastIndexOf("/")
        if (idx > "file:///".length) {
            return url.substring(0, idx)
        }
        return url
    }
}

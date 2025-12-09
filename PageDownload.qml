import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.expample.rkupgradetool 1.0
Item {
    id: pageDownloadRoot

    property int colW_Index: 40
    property int colW_Check: 40
    property int colW_Addr: 100
    property int colW_Name: 100

    // 表头组件 (内部组件)
    component HeaderCell: Item {
        property alias text: txt.text
        Text {
            id: txt; anchors.centerIn: parent; font.pixelSize: 12
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. 表头
        Rectangle {
            id: listHeader
            Layout.fillWidth: true
            height: 25
            color: "#E1E1E1"
            border.color: "#ADADAD"
            z: 2

            Row {
                anchors.fill: parent
                HeaderCell { width: colW_Index; height: parent.height; text: "#" }
                VLine {}
                Item {
                    width: colW_Check; height: parent.height
                    CheckBox { anchors.centerIn: parent; checked: false; scale: 0.7; enabled: false }
                }
                VLine {}
                HeaderCell { width: colW_Addr; height: parent.height; text: "地址" }
                VLine {}
                HeaderCell { width: colW_Name; height: parent.height; text: "名字" }
                VLine {}
                Item {
                    width: listHeader.width - (colW_Index + colW_Check + colW_Addr + colW_Name + 4)
                    height: parent.height
                    Text { text: "路径"; anchors.verticalCenter: parent.verticalCenter; x: 5; font.pixelSize: 12 }
                }
            }
        }

        // 2. 列表视图
        ListView {
            id: partitionList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            model:
                ListModel {
                ListElement { idx: "1"; addr: "0x00000000"; name: "Loader"; path: ""; isChecked: true; isHighlight: true }
                ListElement { idx: "2"; addr: "0x00000000"; name: "Parameter"; path: ""; isChecked: false; isHighlight: false }
                ListElement { idx: "3"; addr: "0x00004000"; name: "uboot"; path: ""; isChecked: false; isHighlight: false }
                ListElement { idx: "4"; addr: "0x00006000"; name: "misc"; path: ""; isChecked: false; isHighlight: false }
                ListElement { idx: "5"; addr: "0x00008000"; name: "boot"; path: ""; isChecked: false; isHighlight: false }
                ListElement { idx: "6"; addr: "0x00028000"; name: "recovery"; path: ""; isChecked: false; isHighlight: false }
                ListElement { idx: "7"; addr: "0x0006A000"; name: "backup"; path: ""; isChecked: false; isHighlight: false }
                ListElement { idx: "8"; addr: "0x00078000"; name: "userdata"; path: ""; isChecked: false; isHighlight: false }
                ListElement { idx: "9"; addr: "0x00278000"; name: "oem"; path: ""; isChecked: false; isHighlight: false }
                ListElement { idx: "10"; addr: "0x002C6000"; name: "rootfs"; path: ""; isChecked: true; isHighlight: false }
            }

            delegate: Rectangle {
                width: partitionList.width
                height: 22
                color: isHighlight ? "#00FF00" : "white"

                Row {
                    anchors.fill: parent

                    // 序号
                    Item { width: colW_Index; height: parent.height; Text { text: idx; anchors.centerIn: parent; font.pixelSize: 12 } }
                    VLine { color: "#E0E0E0" }

                    // 复选框
                    Item {
                        width: colW_Check; height: parent.height
                        CheckBox {
                            anchors.centerIn: parent; checked: isChecked; scale: 0.7; width: 20; height: 20
                            onCheckedChanged: model.isChecked = checked
                        }
                    }
                    VLine { color: "#E0E0E0" }

                    // 地址 (可编辑)
                    EditableCell {
                        isReadOnly: true
                        width: colW_Addr; height: parent.height
                        cellText: addr
                        onCommit: (newVal) => { model.addr = newVal }
                    }
                    VLine { color: "#E0E0E0" }

                    // 名字 (可编辑)
                    EditableCell {
                        isReadOnly: true
                        width: colW_Name; height: parent.height
                        cellText: name
                        onCommit: (newVal) => { model.name = newVal }
                    }
                    VLine { color: "#E0E0E0" }

                    // 路径 (可编辑)
                    EditableCell {
                        width: parent.width - (colW_Index + colW_Check + colW_Addr + colW_Name + 4)
                        height: parent.height
                        cellText: path
                        textAlign: Text.AlignLeft
                        onCommit: (newVal) => { model.path = newVal }
                    }
                }
                Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: "#F0F0F0" }
            }
        }

        // 3. 底部按钮区
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: "#F0F0F0"
            RowLayout {
                anchors.centerIn: parent
                spacing: 20
                Text { text: "Loader:"; font.pixelSize: 12 }
                RkButton {
                    text: "执行"
                    onClicked: {
                        RkUpTool.downloadImage(getCheckedPartitionString())
                    }
                }
                RkButton {  text: "切换"
                            onClicked: {
                                RkUpTool.changeToLoader();
                            }
                        }
                RkButton { text: "设备分区表";
                            implicitWidth: 100;
                            onClicked: {
                                RkUpTool.getPartitionList();
                            }
                }
                // RkButton { text: "清空" }
            }
        }
    }

    // 定义解析并更新的函数
    function updatePartitionsFromText(responseText) {
        if(responseText === "")
            return
        // 获取 Model 引用
        var listModel = partitionList.model

        // 1. 清空现有数据
        listModel.clear()

        // 2. 按行分割文本
        var lines = responseText.split("\n")

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()

            // 3. 过滤无效行
            // 跳过空行、跳过 "Partition Info..." 标题头、跳过 "NO LBA..." 列头
            // 这里判断逻辑是：如果行首不是数字，则跳过
            if (line.length === 0 || !/^\d/.test(line)) {
                continue;
            }

            // 4. 按空白字符分割列
            // 格式: NO(0) LBA(1) Size(2) Name(3)
            // 例子: 01 0x00002000 0x00002000 security
            var parts = line.split(/\s+/)

            if (parts.length >= 4) {
                // 5. 添加到 Model
                listModel.append({
                    "idx": parts[0],        // 序号 (NO)
                    "addr": parts[1],       // 地址 (LBA)
                    "name": parts[3],       // 名字 (Name)
                    "path": "",             // 路径默认为空
                    "isChecked": false,      // 默认勾选 
                    "isHighlight": false    // 默认不高亮
                })
            }
        }
    }

    function getCheckedPartitionString() {
        var listModel = partitionList.model
        var resultParts = []

        // 遍历 Model 中的所有数据
        for (var i = 0; i < listModel.count; i++) {
            // 获取第 i 个元素对象
            var item = listModel.get(i)

            // 判断是否被勾选
            if (item.isChecked) {
                // 获取名字和路径
                var pName = item.name
                var pPath = item.path

                // 如果路径为空，视情况可能需要跳过或保留，这里默认保留
                // 构造格式: -名字 路径 (例如: -boot /path/to/boot.img)
                resultParts.push("-" + pName.trim())
                resultParts.push(pPath.trim())
            }
        }

        // 将数组用空格连接成一个长字符串
        return resultParts
    }
}


import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.expample.rkupgradetool 1.0
import QtQuick.Dialogs 1.3 
import Qt.labs.settings 1.0 

Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Settings {
            id: upgradeSettings
            category: "UpgradePage"
            property string savedFirmwarePath: "file:///"
            property string savedFolderUrl: "file:///"
        }

        Component.onCompleted: {
            firmPathText.text = upgradeSettings.savedFolderUrl
        }


        CustomFileDialog {
            id: myFileDialog
            currentFolder: upgradeSettings.savedFirmwarePath
            nameFilters: ["*.img"]

            onFileSelected: (filePath) => {
                console.log("用户选择了文件: " + filePath)
                upgradeSettings.savedFirmwarePath = parentUrl("file://" + filePath)
                upgradeSettings.savedFolderUrl = filePath
                firmPathText.text = filePath
                AppState.allButtonEnabled = true
            }

            onCancel: {
                AppState.allButtonEnabled = true
            }
        }

        // 顶部大按钮
        RowLayout {
            spacing: 1
            RkButton {  text: "固件";
                        implicitHeight: 35;
                        onClicked: myFileDialog.open();
            }
            RkButton {  text: "升级";
                        implicitHeight: 35;
                        onClicked: {
                            console.debug("onclick");
                            RkUpTool.startUpgrade(firmPathText.text);
                        }
            }
            RkButton {  text: "切换";
                        implicitHeight: 35;
                        onClicked: {
                            RkUpTool.changeToLoader();
                        }
            }
            // RkButton { text: "擦除Flash"; implicitHeight: 35 }
        }

        // 信息区
        GridLayout {
            columns: 6
            rowSpacing: 10
            columnSpacing: 10

            Text { text: "固件版本:"; font.pixelSize: 14 }
            Rectangle {
                width: 60; height: 22; border.color: "#ADADAD"
                Text { anchors.centerIn: parent; text: "5.3.7"; font.pixelSize: 12 }
            }

            Text { text: "Loader版本:"; font.pixelSize: 14; Layout.leftMargin: 20 }
            Rectangle {
                width: 60; height: 22; border.color: "#ADADAD"
                Text { anchors.centerIn: parent; text: "5.37"; font.pixelSize: 12 }
            }

            Text { text: "芯片信息:"; font.pixelSize: 14; Layout.leftMargin: 20 }
            Rectangle {
                width: 70; height: 22; color: "#0078D7"
                Text { anchors.centerIn: parent; text: "RK35XX"; color: "white"; font.pixelSize: 12; font.bold: true }
            }
        }

        // 固件路径
        RowLayout {
            Layout.fillWidth: true
            Text {text: "固件:"; font.pixelSize: 14 }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 40
                border.color: "#ADADAD"; color: "#F9F9F9"
                Text {
                    id: firmPathText;
                    anchors.fill: parent; anchors.margins: 5
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 12; elide: Text.ElideMiddle
                    text: ""
                }
            }
        }

        Item { Layout.fillHeight: true } // 占位填充
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

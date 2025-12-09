import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.expample.rkupgradetool 1.0
import App 1.0
ApplicationWindow {
    visible: true
    width: 900
    height: 500
    title: "瑞芯微开发工具 v5.37"
    color: "#F0F0F0"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. 顶部 Tab 栏
        TabBar {
            id: bar
            Layout.fillWidth: true
            background: Rectangle { color: "#F0F0F0" }
            spacing: 0

            TabButton { width: 100; contentItem: Text { text: "下载镜像"; color: "black"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } }
            TabButton { width: 100; contentItem: Text { text: "升级固件"; color: "black"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } }
            TabButton { width: 100; contentItem: Text { text: "高级功能"; color: "black"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } }
        }

        // 2. 中间内容区 (左侧功能 + 右侧日志)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            Layout.margins: 10

            // 左侧：多页面切换区
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.65
                color: "transparent"
                border.color: "#BCBCBC"

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 1
                    currentIndex: bar.currentIndex

                    // 页面 1: 下载镜像
                    PageDownload {
                        id: pageDownload
                    }

                    // 页面 2: 升级固件
                    PageUpgrade { }

                    Item {
                        Text {
                            anchors.centerIn: parent
                            text: "i am do not want to do that"
                            font.pixelSize: 30
                        }
                    }

                }
            }

            // 右侧：日志区 (保持简单，暂时不需要单独拆分)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"
                border.color: "#BCBCBC"
                border.width: 1

                ScrollView {
                    anchors.fill: parent
                    padding: 0
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                    TextArea {
                        id: logArea
                        anchors.fill: parent

                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0

                        wrapMode: TextArea.Wrap
                        readOnly: true
                        // placeholderText: "Log output..."

                        onTextChanged: {
                            cursorPosition = length
                        }
                    }
                }
            }

        }

        // 3. 底部状态栏
        Rectangle {
            id: buttomState
            Layout.fillWidth: true
            height: 30
            color: "#F0F0F0"
            border.color: "#D0D0D0"
            border.width: 1

            // 定义状态文本
            property string unknow: "没有发现设备"
            property string adb: "发现ADB设备"
            property string loader: "发现LOADER设备"
            property string mloader: "发现多个LOADER设备"
            property string madb: "发现多个ADB设备"
            property var states: RkUpTool.Unknown

            // 定时器，每秒检查设备状态
            Timer {
                id: myTimer
                interval: 1000  // 每秒触发一次
                running: true   // 启动定时器
                repeat: true    // 设定定时器重复触发

                onTriggered: {
                    var states = RkUpTool.getState()
                    // console.log("Device state:", states)
                    // 根据不同的状态更新文本
                    if (states === RkUpTool.Unknown) {
                        buttomStateText.text = buttomState.unknow
                    } else if (states === RkUpTool.ADB) {
                        buttomStateText.text = buttomState.adb
                    } else if (states === RkUpTool.LOADER) {
                        buttomStateText.text = buttomState.loader
                    } else if (states === RkUpTool.MLOADER) {
                        buttomStateText.text = buttomState.mloader
                    } else if (states === RkUpTool.MADB) {
                        buttomStateText.text = buttomState.madb
                    } else {
                        console.warn("unkonw type");
                    }

                }
            }

            // 显示文本的Text控件
            Text {
                id: buttomStateText
                text: buttomState.unknow  // 默认显示 "没有发现设备"
                anchors.centerIn: parent
                font.pixelSize: 18
                font.bold: true
                font.family: "SimSun"
            }
        }
    }
    Connections {
        target: RkUpTool

        function onChangeLoaderFinsh(finish) {
            console.log("加载 Loader 结束:", finish)
            AppState.allButtonEnabled = true
        }

        function onUpgradeFinsh(finish) {
            console.log("升级结束:", finish)
            AppState.allButtonEnabled = true
        }

        function onGetPartitionListFinsh(str, finish) {
            console.log("分区列表:", str, "完成:", finish)
            pageDownload.updatePartitionsFromText(str)
            AppState.allButtonEnabled = true
        }

        function onEraseFlashFinsh(finish) {
            console.log("擦除 Flash 完成:", finish)
            AppState.allButtonEnabled = true
        }

        function onLogRecve(str) {
            console.log("日志接收:", str)
            logArea.text += str
        }
    }




}

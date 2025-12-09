import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.folderlistmodel 2.15

Popup {
    id: root

    // --- 公共属性 ---
    property alias nameFilters: folderModel.nameFilters
    property alias currentFolder: folderModel.folder
    property string selectedFile: ""

    // 信号
    signal fileSelected(string filePath)
    signal cancel()

    // --- 弹窗配置 ---
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay
    width: 600
    height: 450

    background: Rectangle {
        color: "#2b2b2b"
        radius: 8
        border.color: "#444"
        border.width: 1
        Rectangle {
            z: -1; anchors.fill: parent; anchors.margins: -4
            color: "#000000"; opacity: 0.3; radius: 12
        }
    }

    // --- 逻辑处理 ---

    // 1. URL -> 可读路径 (用于显示)
    function formatPath(path) {
        var p = path.toString();
        // 去掉 file:// (Unix) 或 file:/// (Windows)
        // Windows 下 file:///C:/... 变成 C:/...
        // Unix 下 file:///home/... 变成 /home/...
        if (Qt.platform.os === "windows") {
            return p.replace(/^(file:\/{3})/, "");
        } else {
            return p.replace(/^(file:\/{2})/, "");
        }
    }

    // 2. 用户输入 -> URL (用于跳转)
    function parseAndGo(inputPath) {
        var p = inputPath.trim();
        // 简单的反斜杠替换
        p = p.replace(/\\/g, "/");

        // 如果已经是 file: 开头，直接用
        if (p.startsWith("file:")) {
            folderModel.folder = p;
            return;
        }

        // 补全协议头
        if (p.startsWith("/")) {
            // Unix 绝对路径 /home/user -> file:///home/user
            folderModel.folder = "file://" + p;
        } else {
            // Windows 路径 C:/Users -> file:///C:/Users
            // 或者只是为了保险起见，Qt 处理本地文件通常用 file:///
            folderModel.folder = "file:///" + p;
        }
    }

    function goUp() {
        if (folderModel.parentFolder.toString() !== "") {
            folderModel.folder = folderModel.parentFolder;
        }
    }

    // --- 界面布局 ---
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // === 1. 顶部标题栏 (已修改) ===
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "⬆"
                ToolTip.visible: hovered
                ToolTip.text: "返回上一级"
                palette.buttonText: "white"
                background: Rectangle {
                    color: parent.down ? "#555" : "#3e3e3e"
                    radius: 4
                }
                onClicked: root.goUp()
            }

            // --- 核心修改：可编辑的地址栏 ---
            TextField {
                id: pathField
                Layout.fillWidth: true
                selectByMouse: true // 允许鼠标选中文字
                color: "#ffffff"
                selectionColor: "#007bff"
                font.pixelSize: 14

                // 背景样式
                background: Rectangle {
                    color: "#1e1e1e"
                    border.color: pathField.activeFocus ? "#007bff" : "#444"
                    radius: 4
                }

                // 初始绑定：当 Model 变动时，更新文本框显示
                // 使用 Connection 确保双向逻辑不冲突
                Connections {
                    target: folderModel
                    function onFolderChanged() {
                        pathField.text = root.formatPath(folderModel.folder)
                    }
                }
                
                // 初始化显示
                Component.onCompleted: text = root.formatPath(folderModel.folder)

                // 监听回车键：执行跳转
                onAccepted: {
                    root.parseAndGo(text)
                    // 强制失去焦点，或者保持焦点看个人喜好
                    // focus = false 
                }
            }
            
            // 添加一个“前往”按钮，方便纯鼠标操作
            Button {
                text: "Go"
                palette.buttonText: "white"
                background: Rectangle {
                    color: parent.down ? "#0056b3" : "#3e3e3e"
                    radius: 4
                }
                onClicked: root.parseAndGo(pathField.text)
            }
        }

        // 2. 分隔线
        Rectangle {
            Layout.fillWidth: true; height: 1; color: "#444"
        }

        // 3. 文件列表区域
        ListView {
            id: fileListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: FolderListModel {
                id: folderModel
                showDirs: true
                showFiles: true
                showDotAndDotDot: false
                nameFilters: ["*.*"]
                sortField: FolderListModel.Type
                
                // 默认路径：可以设为系统主目录，避免空路径报错
                folder: "file:///" 
            }

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: delegateRect
                width: ListView.view.width
                height: 40
                color: {
                    if (delegateArea.pressed) return "#505050"
                    if (root.selectedFile === fileUrl.toString()) return "#3a3a4c"
                    if (delegateArea.containsMouse) return "#333333"
                    return "transparent"
                }
                radius: 4

                MouseArea {
                    id: delegateArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (fileIsDir) {
                            folderModel.folder = fileUrl
                        } else {
                            root.selectedFile = fileUrl.toString()
                        }
                    }
                    onDoubleClicked: {
                        if (!fileIsDir) {
                            root.selectedFile = fileUrl.toString()
                            root.accept()
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 10
                    Rectangle {
                        width: 24; height: 24
                        color: fileIsDir ? "#E6C65F" : "#7A90A2"
                        radius: 3
                        Text {
                            anchors.centerIn: parent
                            text: fileIsDir ? "D" : "F"
                            font.pixelSize: 10; color: "black"
                        }
                    }
                    Text {
                        text: fileName
                        color: "#dddddd"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // 4. 底部按钮栏
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 10
            Text {
                text: root.selectedFile !== "" ? root.selectedFile.split("/").pop() : "未选择"
                color: "#888"
                Layout.fillWidth: true
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignRight
            }
            Button {
                text: "取消"
                background: Rectangle { color: parent.down ? "#555" : "#3e3e3e"; radius: 4 }
                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: { root.cancel(); root.close() }
            }
            Button {
                text: "打开"
                enabled: root.selectedFile !== ""
                background: Rectangle { color: parent.enabled ? (parent.down ? "#0056b3" : "#007bff") : "#2a2a2a"; radius: 4 }
                contentItem: Text { text: parent.text; color: parent.enabled ? "white" : "#555"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: root.accept()
            }
        }
    }

    function accept() {
        if (selectedFile !== "") {
            fileSelected(formatPath(selectedFile))
            close()
        }
    }
}
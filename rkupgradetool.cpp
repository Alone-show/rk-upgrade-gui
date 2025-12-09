#include "rkupgradetool.h"

// 初始化静态成员
RkUpgradeTool *RkUpgradeTool::m_instance = nullptr;

RkUpgradeTool::RkUpgradeTool(QObject *parent)
    : QObject(parent)
{
    // 如果实例已存在，打印警告
    if (m_instance) {
        qWarning() << "RkUpgradeTool instance already exists!";
    } else {
        m_instance = this;
    }
}

RkUpgradeTool::~RkUpgradeTool()
{
    if(m_RkDlProcess)
    {
        delete m_RkDlProcess;
        m_RkDlProcess = nullptr;
    }
    if (m_instance == this) {
        m_instance = nullptr;
    }
}

RkUpgradeTool *RkUpgradeTool::instance()
{
    // 懒汉式加载
    if (!m_instance) {
        m_instance = new RkUpgradeTool();
    }
    return m_instance;
}

/**
 * @brief 开始执行固件升级流程
 * @param path 固件文件的路径
 * 
 * 该函数通过调用RK升级工具来执行固件升级操作。它会启动一个进程来运行
 * rk_upgrade_tool命令，并传入"UF"参数和固件路径来开始升级。
 */
void RkUpgradeTool::startUpgrade(QString path)
{
    startProcess(m_RkDlProcess, "rk_upgrade_tool", {"UF", path},
                 [this](int exitCode, QProcess::ExitStatus exitStatus){  
                     if(exitCode == 0)
                     {
                         emit upgradeFinsh(true);
                     }
                     else{
                         emit upgradeFinsh(false);
                     }
                 },
                 [this](QString str){
                     emit logRecve(str);
                 });
}

/**
 * @brief 切换到loader模式
 * 
 * 该函数通过调用RK升级工具来切换到loader模式。
 * 执行结果通过信号发送给调用者。
 * 
 * @note 该函数不接受任何参数
 * @note 该函数没有返回值，通过信号传递执行结果
 */
void RkUpgradeTool::changeToLoader()
{
    startProcess(m_RkDlProcess, "adb", {"reboot", "loader"},
                [this](int exitCode, QProcess::ExitStatus exitStatus){
                    if(exitCode == 0)
                    {
                        emit changeLoaderFinsh(true);
                    }
                    else{
                        emit changeLoaderFinsh(false);
                    }
                },
                [this](QString str){
                     emit logRecve(str);
                });
}

/**
 * @brief 获取分区列表
 * 
 * 通过启动rk_upgrade_tool工具执行PL命令来获取设备的分区列表信息。
 * 执行结果通过信号发送给调用者。
 * 
 * @note 该函数不接受任何参数
 * @note 该函数没有返回值，通过信号传递执行结果
 */
void RkUpgradeTool::getPartitionList()
{
    startProcess(m_RkDlProcess, "rk_upgrade_tool", {"PL"},
                 [this](int exitCode, QProcess::ExitStatus exitStatus, QString data){
                     if(exitCode == 0)
                     {
                         emit getPartitionListFinsh(data, true);
                         emit logRecve(data);
                     }
                     else{
                         emit getPartitionListFinsh("", false);
                         emit logRecve(data);
                     }
    });
}

/**
 * @brief 下载镜像文件
 * @param list 镜像文件列表
 * 
 * 该函数用于启动下载镜像的过程，通过调用rk_upgrade_tool工具来执行下载操作。
 * 函数会构建相应的命令行参数，并启动进程执行下载任务。
 */
void RkUpgradeTool::downloadImage(QStringList list)
{
    QStringList arg;
    arg << "DI" << list;

    startProcess(m_RkDlProcess, "rk_upgrade_tool", arg,
                 [this](int exitCode, QProcess::ExitStatus exitStatus){
                     if(exitCode == 0)
                     {
                         emit upgradeFinsh(true);
                     }
                     else{
                         emit upgradeFinsh(false);
                     }
                 },
                 [this](QString str){
                     emit logRecve(str);
                 });
}


void RkUpgradeTool::startProcess(QProcess *process,
                                 const QString &command,
                                 const QStringList &arguments,
                                 std::function<void(int exitCode, QProcess::ExitStatus exitStatus)> finshCallback,
                                 std::function<void(QString str)> recevCallback)
{

    qDebug() << "startProcess" << command << arguments;
    if (!process) {
        process = new QProcess(this);
    }

    if (process->state() != QProcess::NotRunning) {
        qWarning() << "Process is already running for command:" << command << arguments;
        finshCallback(-1, QProcess::ExitStatus::CrashExit);
        return;
    }

    process->disconnect();

    // 连接 finished 信号，并执行回调
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, finshCallback, process](int exitCode, QProcess::ExitStatus exitStatus) {
                // 确保进程没有被删除
                if (process) {
                    // 执行回调
                    QString program = process->program();
                    QStringList args = process->arguments();
                    qDebug() << "Process finished for command:" << program << args << "with exit code:" << exitCode ;
                    finshCallback(exitCode, exitStatus);
                }
            });

    connect(process, &QProcess::readyReadStandardOutput, this, [process,recevCallback](){
        if(process)
        {
            QByteArray data = process->readAllStandardOutput();
            // qDebug() << "STDOUT:" << data;
            recevCallback(QString(data));
        }
        else{
            // qWarning() << "error";
        }
    });
    connect(process, &QProcess::readyReadStandardError, this, [process, recevCallback](){
        if(process)
        {
            QByteArray data = process->readAllStandardError();
            // qDebug() << "ERROUT:" << data;
            recevCallback(QString(data));
        }
        else{
            // qWarning() << "error";
        }
    });

    // 启动进程
    process->start(command, arguments);
}

void RkUpgradeTool::startProcess(QProcess *process,
                                 const QString &command,
                                 const QStringList &arguments,
                                 std::function<void(int exitCode, QProcess::ExitStatus exitStatus, QString output)> finshCallback)
{
    // 如果 process 为 nullptr，则创建一个新的 QProcess 实例
    qDebug() << "startProcess" << command << arguments;
    if (!process) {
        process = new QProcess(this);
    }
    // 如果进程正在运行，发出警告
    if (process->state() != QProcess::NotRunning) {
        qWarning() << "Process is already running for command:" << command << arguments;
        finshCallback(-1, QProcess::ExitStatus::CrashExit, "");
        return;
    }

    process->disconnect();

    // 连接 finished 信号，并执行回调
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, finshCallback, process](int exitCode, QProcess::ExitStatus exitStatus) {
                if (process) {
                    // 执行回调
                    QString program = process->program();
                    QStringList args = process->arguments();
                    qDebug() << "Process finished for command:" << program << args << "with exit code:" << exitCode ;
                    QByteArray data = process->readAllStandardOutput();
                    finshCallback(exitCode, exitStatus, QString(data));
                }
            });
    // 启动进程
    process->start(command, arguments);
}




int RkUpgradeTool::getLoaderDeviceNum()
{
    QProcess process;
    process.start("rk_upgrade_tool", {"LD"});

    if (!process.waitForFinished()) {
        qWarning() << "Process failed to finish!";
        return -1;
    }

    QByteArray output = process.readAllStandardOutput();

    // qDebug() << "Command output:" << output;

    // 解析输出并计算设备数量
    // "List of rockusb connected(2)"
    QString outputStr = QString(output);
    QRegExp regex("List of rockusb connected\\((\\d+)\\)");
    if (regex.indexIn(outputStr) != -1) {
        // 获取设备数量
        int deviceCount = regex.cap(1).toInt();
        // qDebug() << "Loader Device count:" << deviceCount;
        return deviceCount;
    }
}

int RkUpgradeTool::getAdbDeviceNum()
{
    QProcess process;
    process.start("adb", {"devices"});
    
    if (!process.waitForFinished()) {
        qWarning() << "Failed to run adb devices command!";
        return -1;  // 如果命令失败，返回 -1
    }

    QByteArray output = process.readAllStandardOutput();

    // qDebug() << "ADB devices output:" << output;

    // 解析输出，获取设备数量
    QString outputStr = QString(output);
    QStringList lines = outputStr.split('\n', QString::SkipEmptyParts);

    // 设备数量从第二行开始（第一行是标题）
    int deviceCount = 0;
    for (const QString &line : lines) {
        // 只考虑设备处于 "device" 状态的行
        if (line.contains("\tdevice")) {
            deviceCount++;
        }
    }
    // qDebug() << "ADB Device count:" << deviceCount;
    return deviceCount;

}


/**
 * @brief 获取设备当前状态
 * 
 * 该函数通过检测loader模式和adb模式下的设备数量来判断设备状态。
 * 首先检查loader模式设备，如果存在则返回对应状态；
 * 否则检查adb模式设备并返回相应状态。
 * 
 * @return DeviceStatus 设备状态枚举值
 *         - Unknown: 无设备连接
 *         - LOADER: 单个loader设备
 *         - MLOADER: 多个loader设备
 *         - ADB: 单个adb设备
 *         - MADB: 多个adb设备
 */
RkUpgradeTool::DeviceStatus RkUpgradeTool::getState()
{
    int loaderDeviceNum = getLoaderDeviceNum();
    switch (loaderDeviceNum) {
        case 0:
            break;
        case 1:
            return DeviceStatus::LOADER;
        default:
            return DeviceStatus::MLOADER;
    }

    int adbDeviceNum = getAdbDeviceNum();
    switch (adbDeviceNum) {
        case 0:
            return DeviceStatus::Unknown;
        case 1:
            return DeviceStatus::ADB;
        default:
            return DeviceStatus::MADB;
    }
}

QObject* RkUpgradeTool::instance(QQmlEngine* engine, QJSEngine* scriptEngine) {
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    if (!m_instance) {
        m_instance = new RkUpgradeTool();
    }
    return m_instance;
}




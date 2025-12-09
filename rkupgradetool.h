#ifndef RKUPGRADETOOL_H
#define RKUPGRADETOOL_H

#include <QObject>
#include <QQmlEngine>
#include <QDebug>
#include <QProcess>


class RkUpgradeTool : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum class DeviceStatus {
        Unknown = 0,
        ADB,
        LOADER,
        MADB,
        MLOADER
    };
    Q_ENUM(DeviceStatus)

    // 获取 C++ 单例实例的静态方法
    static RkUpgradeTool *instance();
    static QObject *instance(QQmlEngine* engine, QJSEngine* scriptEngine);

    ~RkUpgradeTool() override;

    // 供 QML 调用的方法
    Q_INVOKABLE void startUpgrade(QString path);
    Q_INVOKABLE DeviceStatus getState();
    Q_INVOKABLE void changeToLoader();
    Q_INVOKABLE void getPartitionList();
    Q_INVOKABLE void downloadImage(QStringList strList);


signals:
    //true ==> success
    void changeLoaderFinsh(bool fnish);
    void upgradeFinsh(bool fnish);
    void getPartitionListFinsh(QString str, bool finsh);
    void eraseFlashFinsh(bool finsh);
    void logRecve(QString str);

private:
    // 禁止拷贝和赋值
    Q_DISABLE_COPY(RkUpgradeTool)
    explicit RkUpgradeTool(QObject *parent = nullptr);
    int getLoaderDeviceNum();
    int getAdbDeviceNum();
    void startProcess(QProcess *process ,
                      const QString &command,
                      const QStringList &arguments,
                      std::function<void(int exitCode, QProcess::ExitStatus exitStatus)> callback,
                      std::function<void(QString str)> recevCallback);

    void startProcess(QProcess *process ,
                      const QString &command,
                      const QStringList &arguments,
                      std::function<void(int exitCode, QProcess::ExitStatus exitStatus, QString output)> callback);


    QProcess* m_RkDlProcess{nullptr};
    // 静态指针存储实例
    static RkUpgradeTool *m_instance;
};

#endif // RKUPGRADETOOL_H

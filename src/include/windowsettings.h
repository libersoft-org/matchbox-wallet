#ifndef WINDOWSETTINGS_H
#define WINDOWSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QQmlEngine>
#include <QTimer>

class WindowSettings : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int x READ x WRITE setX NOTIFY xChanged)
    Q_PROPERTY(int y READ y WRITE setY NOTIFY yChanged)
    Q_PROPERTY(int width READ width WRITE setWidth NOTIFY widthChanged)
    Q_PROPERTY(int height READ height WRITE setHeight NOTIFY heightChanged)

public:
    explicit WindowSettings(QObject *parent = nullptr);
    
    int x() const { return m_x; }
    void setX(int x);
    
    int y() const { return m_y; }
    void setY(int y);
    
    int width() const { return m_width; }
    void setWidth(int width);
    
    int height() const { return m_height; }
    void setHeight(int height);

    Q_INVOKABLE void save();
    Q_INVOKABLE void load();

signals:
    void xChanged();
    void yChanged();
    void widthChanged();
    void heightChanged();

private slots:
    void saveSettingsDelayed();

private:
    void loadSettings();
    void saveSettings();
    
    QSettings *m_settings;
    QTimer *m_saveTimer;
    int m_x;
    int m_y;
    int m_width;
    int m_height;
};

#endif // WINDOWSETTINGS_H
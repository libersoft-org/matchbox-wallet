#include "include/windowsettings.h"
#include <QDebug>
#include <QCoreApplication>

WindowSettings::WindowSettings(QObject *parent) : QObject(parent), m_settings(new QSettings(QCoreApplication::organizationName(), QCoreApplication::applicationName(), this)), m_saveTimer(new QTimer(this)), m_x(0), m_y(0), m_width(481), m_height(640) {
	m_saveTimer->setSingleShot(true);
	m_saveTimer->setInterval(500); // Save after 500ms delay
	connect(m_saveTimer, &QTimer::timeout, this, &WindowSettings::saveSettingsDelayed);
	loadSettings();
}

void WindowSettings::setX(int x) {
	if (m_x != x) {
		m_x = x;
		emit xChanged();
		m_saveTimer->start(); // Restart timer for delayed save
	}
}

void WindowSettings::setY(int y) {
	if (m_y != y) {
		m_y = y;
		emit yChanged();
		m_saveTimer->start(); // Restart timer for delayed save
	}
}

void WindowSettings::setWidth(int width) {
	if (m_width != width) {
		m_width = width;
		emit widthChanged();
		m_saveTimer->start(); // Restart timer for delayed save
	}
}

void WindowSettings::setHeight(int height) {
	if (m_height != height) {
		m_height = height;
		emit heightChanged();
		m_saveTimer->start(); // Restart timer for delayed save
	}
}

void WindowSettings::save() {
	saveSettings();
}

void WindowSettings::load() {
	loadSettings();
}

void WindowSettings::loadSettings() {
	m_x = m_settings->value("window/x", 0).toInt();
	m_y = m_settings->value("window/y", 0).toInt();
	m_width = m_settings->value("window/width", 481).toInt();
	m_height = m_settings->value("window/height", 640).toInt();

	qDebug() << "WindowSettings loaded - x:" << m_x << "y:" << m_y << "width:" << m_width << "height:" << m_height;
}

void WindowSettings::saveSettingsDelayed() {
	saveSettings();
}

void WindowSettings::saveSettings() {
	m_settings->setValue("window/x", m_x);
	m_settings->setValue("window/y", m_y);
	m_settings->setValue("window/width", m_width);
	m_settings->setValue("window/height", m_height);
	m_settings->sync();
}

// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

#include "notesbackend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>

NotesBackend::NotesBackend(const QString & dirName) : m_directory(dirName)
{
    if (!QDir(m_directory).exists())
        QDir::root().mkdir(m_directory);
}

bool NotesBackend::write_note(const QString & name, const QString & content)
{
    // write_note should only write to files inside m_directory.
    // baseName enforces this as a side effect because it strips out
    // the path (if any).
    QString fileName(QFileInfo(name).baseName() + ".txt");
    QFile file(QDir(m_directory).filePath(fileName));
    QByteArray data(content.toUtf8());

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;
    if (file.write(data) != data.length())
        return false;
    return file.flush();
}

QString NotesBackend::read_note(const QString & name)
{
    QString fileName(QFileInfo(name).baseName() + ".txt");
    QFile file(QDir(m_directory).filePath(fileName));
    // Reading notes that don't exist yet is not an error; they're just empty.
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return QString();
    QByteArray content = file.readAll();
    return QString::fromUtf8(content.constData(), content.length());
}

QString NotesBackend::new_note()
{
    QDir dir(m_directory);
    for (int i = 1; ; i++) {
        QString name = QString("note%1.txt").arg(i);
        if (!dir.exists(name)) {
            write_note(name, "");
            return name;
        }
    }
}

bool NotesBackend::delete_note(const QString & name)
{
    QString fileName(QFileInfo(name).baseName() + ".txt");
    return QFile::remove(QDir(m_directory).filePath(fileName));
}

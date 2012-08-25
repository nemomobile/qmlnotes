// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

#ifndef NOTESBACKEND_H
#define NOTESBACKEND_H

#include <QObject>
#include <QString>

/*!
 * \brief Provide a handler for reading and writing notes in a directory
 * This class is intended to be placed in the QML root context,
 * so that its functions can be invoked from javascript.
 */
class NotesBackend : public QObject
{
    Q_OBJECT

public:
    /*!
     * \param \a dirName is the directory in which all note files reside.
     */
    NotesBackend(const QString & dirName);

    /*!
     * \brief Write a note to the filesystem
     * This will replace a note of the same name, if any.
     * Notes are always encoded as UTF-8.
     * \return true on success
     */
    Q_INVOKABLE bool write_note(const QString & name, const QString & content);
    /*!
     * \brief Read a previously written note
     * \return the note contents
     */
    Q_INVOKABLE QString read_note(const QString & name);
    /*!
     * \brief Allocate a new note file and return its name.
     * The name will be reserved and calling write_note with
     * this name will not overwrite any other note.
     */
    Q_INVOKABLE QString new_note();
    /*!
     * \brief Remove a note from the filesystem
     * \return true on success
     */
    Q_INVOKABLE bool delete_note(const QString & name);

private:
    QString m_directory;
};

#endif

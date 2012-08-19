#!/bin/bash

set -e

NOTES_DIR="$HOME/Notes"
STASH_DIR="$HOME/Notes.test-stash"

DB_DIR="$HOME/.local/share/data/QML/OfflineStorage/Databases"
# "qmlnotes" as encoded by QML OfflineStorage
DB_NAME="1ad6e6d9437aa20aeb62cc788dba5ea2"

NOTES_INI="$DB_DIR/$DB_NAME.ini"
NOTES_STASH_INI="$DB_DIR/$DB_NAME.test_stash.ini"
NOTES_DB="$DB_DIR/$DB_NAME.sqlite"
NOTES_STASH_DB="$DB_DIR/$DB_NAME.test_stash.sqlite"

STASH_FLAG="$HOME/.stashed_notes"

if [ "x$1" = "xstash" ]; then
    # clear the way for a test run
    if [ -d "$NOTES_DIR" ]; then
        if [ -d "$STASH_DIR" ]; then
            rm -rf "$NOTES_DIR"
        else
            mv "$NOTES_DIR" "$STASH_DIR"
        fi
    fi
    if [ -f "$NOTES_INI" ]; then
        if [ -f "$NOTES_STASH_INI" ]; then
            rm -f "$NOTES_STASH_INI" "$NOTES_STASH_DB"
        else
            mv "$NOTES_INI" "$NOTES_STASH_INI"
            mv "$NOTES_DB" "$NOTES_STASH_DB"
        fi
    fi
    touch "$STASH_FLAG"

elif [ "x$1" = "xunstash" ]; then
    # restore the pre-stash state if possible
    if [ -f "$STASH_FLAG" ]; then
        rm -rf "$NOTES_DIR"
        rm -f "$NOTES_INI" "$NOTES_DB"
        rm "$STASH_FLAG"
    fi
    if [ -d "$STASH_DIR" ]; then
        rm -rf "$NOTES_DIR"
        mv "$STASH_DIR" "$NOTES_DIR"
    fi
    if [ -f "$NOTES_STASH_INI" ]; then
        mv "$NOTES_STASH_INI" "$NOTES_INI"
        mv "$NOTES_STASH_DB" "$NOTES_DB"
    fi
fi

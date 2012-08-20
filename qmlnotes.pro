# Copyright (C) 2012 Jolla Ltd.
# Contact: Richard Braakman <richard.braakman@jollamobile.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

PROJECT_NAME = qmlnotes
QT += declarative

target.path = $$INSTALL_ROOT/usr/bin
INSTALLS += target

RESOURCES += res.qrc
SOURCES += main.cpp

SOURCES += notesbackend.cpp
HEADERS += notesbackend.h

TEMPLATE = app
CONFIG -= app_bundle
TARGET = $$PROJECT_NAME

CONFIG += link_pkgconfig

packagesExist(qdeclarative-boostable) {
    message("Building with qdeclarative-boostable support")
    DEFINES += HAS_BOOSTER
    PKGCONFIG += qdeclarative-boostable
} else {
    warning("qdeclarative-boostable not available; startup times will be slower")                                                                         
}

tests.path = $$INSTALL_ROOT/usr/share/qmlnotes-tests
tests.files = tests/tests.xml tests/*.rb tests/notes.sh
tests.extra = (cd tests && ./gen_tests_xml.sh >$$OUT_PWD/tests/tests.xml)
tests.CONFIG = no_check_exist

INSTALLS += tests

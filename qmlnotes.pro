PROJECT_NAME = qmlnotes
QT += declarative

target.path = $$INSTALL_ROOT/usr/bin
INSTALLS += target

RESOURCES += res.qrc
SOURCES += main.cpp

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

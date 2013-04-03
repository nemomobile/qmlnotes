# Copyright (C) 2012 Jolla Ltd.
# Contact: Richard Braakman <richard.braakman@jollamobile.com>

Name:       qmlnotes
Summary:    Note-taking application
Version:    0.3.1
Release:    1
Group:      Applications/System
License:    GPLv2+
URL:        https://github.com/nemomobile/qmlnotes
Source0:    %{name}-%{version}.tar.bz2
Requires:   qt-components
Requires:   %{name}-theme-blanco-extra
BuildRequires:  pkgconfig(QtCore) >= 4.7.0
BuildRequires:  pkgconfig(QtDeclarative)
BuildRequires:  pkgconfig(QtGui)
BuildRequires:  pkgconfig(qdeclarative-boostable)

%description
Note-taking application using Qt Quick

%package tests
Summary:    Unit tests for the note-taking application
Group:      Development/Libraries
Requires:   %{name} = %{version}-%{release}
Requires:   qttas-server
Requires:   rubygem-testability-driver-qt-sut-plugin
Requires:   ruby

%description tests
This package contains unit tests to be run with TDriver and testrunner-lite.

%package theme-blanco-extra
Summary:    Icons and images for qmlnotes

%description theme-blanco-extra
This package contains icons and images for use by qmlnotes.

%prep
%setup -q

%build

%qmake  \
    MEEGO_VERSION_MAJOR=1 \
    MEEGO_VERSION_MINOR=2 \
    MEEGO_VERSION_PATCH=0 \
    MEEGO_EDITION=harmattan \
    DEFINES+=MEEGO_EDITION_HARMATTAN

make %{?jobs:-j%jobs}

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{_datadir}/applications
install -m 0644 qmlnotes.desktop %{buildroot}/%{_datadir}/applications/
%qmake_install
mkdir -p %{buildroot}/%{_datadir}/themes/blanco/meegotouch/images/backgrounds/
install -m 0644 images/notes-background-*.jpg %{buildroot}/%{_datadir}/themes/blanco/meegotouch/images/backgrounds/
mkdir -p %{buildroot}/%{_datadir}/themes/blanco/meegotouch/icons/
install -m 0644 icons/*.png %{buildroot}/%{_datadir}/themes/blanco/meegotouch/icons/

%files
%defattr(-,root,root,-)
%{_bindir}/qmlnotes
%{_datadir}/applications/qmlnotes.desktop

%files tests
%defattr(-,root,root,-)
/opt/tests/qmlnotes/

%files theme-blanco-extra
%defattr(-,root,root,-)
%{_datadir}/themes/blanco/meegotouch/

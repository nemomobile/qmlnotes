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
BuildRequires:  pkgconfig(QtCore) >= 4.7.0
BuildRequires:  pkgconfig(QtDeclarative)
BuildRequires:  pkgconfig(QtGui)
BuildRequires:  pkgconfig(qdeclarative-boostable)

%description
Note-taking application using Qt Quick

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
install -m 0666 qmlnotes.desktop %{buildroot}/%{_datadir}/applications/
%qmake_install

%files
%defattr(-,root,root,-)
%{_bindir}/qmlnotes
%{_datadir}/applications/qmlnotes.desktop

Name:       qmlnotes
Summary:    Note-taking application
Version:    0.1
Release:    1
Group:      Applications/System
License:    BSD
Source0:    %{name}-%{version}.tar.bz2
Source1:    qmlnotes.desktop
Requires:   qt-components
BuildRequires:  pkgconfig(QtCore) >= 4.7.0
BuildRequires:  pkgconfig(QtDeclarative)
BuildRequires:  pkgconfig(QtGui)
BuildRequires:  pkgconfig(qdeclarative-boostable)
BuildRequires:  desktop-file-utils

%description
Note-taking application using Qt Quick

%prep
%setup -q -n %{name}

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
cp %{SOURCE1} %{buildroot}/%{_datadir}/applications/qmlnotes.desktop
%qmake_install

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/qmlnotes
%{_datadir}/applications/qmlnotes.desktop

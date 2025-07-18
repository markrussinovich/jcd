%define __spec_install_post %{nil}
%define __os_install_post %{_dbpath}/brp-compress
%define debug_package %{nil}

Name: jcd
Summary: Enhanced directory navigation tool with substring matching and tab completion cycling
Version: @@VERSION@@
Release: @@RELEASE@@%{?dist}
License: MIT
Group: Applications/System
Source0: %{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

%description
%{summary}

jcd (Jump Change Directory) is a Rust-based command-line tool that provides
enhanced directory navigation with substring matching and smart selection.
It's like the cd command, but with superpowers!

%prep
%setup -q

%build
cargo build --release

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
pwd
ls
install -m 755 ../../../jcd %{buildroot}%{_bindir}/jcd
install -m 755 ../../../jcd_function.sh %{buildroot}%{_bindir}/jcd_function.sh

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_bindir}/jcd
%{_bindir}/jcd_function.sh

%post
echo "JCD (Jump Change Directory) has been installed successfully!"
echo ""
echo "To enable JCD shell integration: source /usr/bin/jcd_function.sh"
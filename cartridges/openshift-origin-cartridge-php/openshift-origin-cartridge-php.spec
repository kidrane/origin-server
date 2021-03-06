%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/php-5.3
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/php-5.3

Name: openshift-origin-cartridge-php
Version: 0.1.2
Release: 1%{?dist}
Summary: Php cartridge
Group: Development/Languages
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      php >= 5.3.2
Requires:      php < 5.4
Requires:      httpd < 2.4
Requires:      php
Requires:      mod_bw
Requires:      rubygem-builder
Requires:      php-devel
Requires:      php-pdo
Requires:      php-gd
Requires:      php-xml
Requires:      php-mysql
Requires:      php-pecl-mongo
Requires:      php-pgsql
Requires:      php-mbstring
Requires:      php-pear
Requires:      php-imap
Requires:      php-pecl-apc
Requires:      php-mcrypt
Requires:      php-soap
Requires:      php-bcmath
Requires:      php-process
Requires:      php-pecl-imagick
Requires:      php-pecl-xdebug

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
PHP cartridge for openshift.


%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp -r * %{buildroot}%{cartridgedir}/


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{frameworkdir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md


%changelog
* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- PHP cart manifest fixup and other cleanup. (mrunalp@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- Fixing tito tags on master

* Wed Mar 13 2013 Mrunal Patel <mrunalp@gmail.com> 0.1.1-1
- new package built with tito

* Wed Feb 13 2013 Mrunal Patel
- new package built with tito

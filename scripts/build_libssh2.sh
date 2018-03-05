#!/bin/bash

version="1.8.0"

my_path=`pwd`

sudo apt-get install unzip cmake build-essential dh-make chrpath

# Prepare build root
rm -rf libssh2-build/
mkdir libssh2-build/ && cd libssh2-build/

# Download
git clone https://github.com/libssh2/libssh2
mkdir -p libssh2/debian

# prepare package metadata
DATE=`date -R`
cat > libssh2/debian/changelog <<EOF
libssh2 (${version}-2ubuntu0.1) xenial-security; urgency=medium

  * Rolling update

 -- root <automake@auto.bots>  Thu, 01 Jan 1970 03:00:00 +0300
EOF

cat > libssh2/debian/control <<EOF
Source: libssh2
Section: libs
Priority: optional
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
XSBC-Original-Maintainer: Mikhail Gusarov <dottedmag@debian.org>
Build-Depends: debhelper (>= 9), dh-autoreconf, libgcrypt20-dev, zlib1g-dev, chrpath
Standards-Version: 3.9.6
Homepage: http://libssh2.org/

Package: libssh2-1
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}
Pre-Depends: \${misc:Pre-Depends}
Multi-Arch: same
Description: SSH2 client-side library
 libssh2 is a client-side C library implementing the SSH2 protocol.
 It supports regular terminal, SCP and SFTP (v1-v5) sessions;
 port forwarding, X11 forwarding; password, key-based and
 keyboard-interactive authentication.
 .
 This package contains the runtime library.

Package: libssh2-1-dev
Section: libdevel
Architecture: any
Depends: libssh2-1 (= \${binary:Version}), \${misc:Depends}, libgcrypt20-dev
Multi-Arch: same
Description: SSH2 client-side library (development headers)
 libssh2 is a client-side C library implementing the SSH2 protocol.
 It supports regular terminal, SCP and SFTP (v1-v5) sessions;
 port forwarding, X11 forwarding; password, key-based and
 keyboard-interactive authentication.
 .
 This package contains the development files.
EOF

cat > libssh2/debian/libssh2-1-dev.install <<EOF
usr/include/*
usr/lib/*/*.a
usr/lib/*/*.so
usr/lib/*/pkgconfig/*.pc
EOF

cat > libssh2/debian/libssh2-1.install <<EOF
usr/lib/*/*.so.*
EOF

cat > libssh2/debian/rules <<EOF
#!/usr/bin/make -f

DEB_HOST_MULTIARCH ?= \$(shell dpkg-architecture -qDEB_HOST_MULTIARCH)

CONFIGURE_EXTRA_FLAGS += --with-libgcrypt --without-openssl
CONFIGURE_EXTRA_FLAGS += --libdir=\\\$\${prefix}/lib/\$(DEB_HOST_MULTIARCH)
CONFIGURE_EXTRA_FLAGS += --disable-rpath

%:
	dh \$@ --parallel --with autoreconf

override_dh_auto_configure:
	dh_auto_configure -- \$(CONFIGURE_EXTRA_FLAGS)

override_dh_installexamples:
	dh_installexamples -a -X .deps -X Makefile -X .gitignore        

override_dh_installchangelogs:
	dh_installchangelogs NEWS

#
# mansyntax.sh test duplicates functionality of debhelper and requires presence
# of en_US.utf8 locale. Ensure it is not run by providing fake man(1) tool.
#
override_dh_auto_test:
	PATH=\$(CURDIR)/debian:\$\$PATH dh_auto_test -a

EOF
chmod a+x libssh2/debian/rules
echo 9 > libssh2/debian/compat

cd libssh2
# prepare build env
./buildconf

dpkg-buildpackage -j32 -us -uc -rfakeroot

cd .. && ls -la *.deb

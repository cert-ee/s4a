#!/bin/bash

version="$1"
# version=3.2.2
if [ -z $version ] ; then
	echo "Usage: $0 <suricata version> [tag]"
	exit
fi

# Setup
# ------------------------------------------------------------------------------
ver="0.3"

DEBEMAIL="automake@auto.bots"
DEBFULLNAME="automake"

git_pfring="https://github.com/ntop/PF_RING.git"
git_pfring_version="tags/${2:-7.2.0}"
git_libhtp="https://github.com/OISF/libhtp.git"
url_suricata="https://www.openinfosecfoundation.org/download/suricata-${version}.tar.gz"
# from PF_RING's  README.FIRST
# https://redmine.openinfosecfoundation.org/projects/suricata/wiki/Ubuntu_Installation
build_deps="autoconf automake autopoint bison build-essential devscripts dh-autoreconf dh-make pv
	dkms flex libcap-ng0 libcap-ng-dev libgcrypt20-dev libgmp-dev libgmpxx4ldbl 
	libgnutls-dev libgnutlsxx28 libgpg-error-dev libidn11-dev libjansson4 libjansson-dev 
	libltdl7 libltdl-dev libluajit-5.1-2 libluajit-5.1-common libluajit-5.1-dev libmagic-dev 
	libnet1 libnet1-dev libnetfilter-log1 libnetfilter-log-dev libnetfilter-queue1 libnetfilter-queue-dev 
	libnfnetlink-dev libnspr4 libnspr4-dev libnss3 libnss3-dev libnss3-nssdb libnuma-dev libp11-kit-dev 
	libpcre3 libpcre3-dbg libpcre3-dev libprelude2v5 libprelude-dev libtasn1-6-dev libtool
	libyaml-0-2 libyaml-dev linux-headers-$(uname -r) make nettle-dev pkg-config zlib1g zlib1g-dev
	libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0 libdaq-dev dpkg-sig"
build_path="${HOME}/suricata-build-${version}"

export MAKEFLAGS="-j 32"

# Functions
# ------------------------------------------------------------------------------
function debbuild_helper() {
	local pkg_name=$1
	shift
	local description=$1
	shift
	local build_options=$1
	shift
	local provides="$*"
	(
		cd $pkg_name
		dh_make -y -c gpl2 -n -s -p pfring-${pkg_name}_${pf_ring_version} >> $build_path/build.pfring-${pkg_name}.log
		sed -i "s/\(Description:.*\)/Replaces: ${provides// /, }\n\\1: $description/" debian/control
		echo -e " [1m*[0m Building pfring-${pkg_name}"
		DEB_BUILD_OPTIONS="$build_options" debuild -j32 -b -uc -us >> $build_path/build.pfring-${pkg_name}.log
	)
}


# Main
# ------------------------------------------------------------------------------
rm -rf $build_path && mkdir $build_path && cd $build_path

echo "[1mSuricata debBuild proccess v$ver[0m"
echo "Magic dust starts to fly around"

#install some build deps
echo -e " [1m*[0m Installing build deps"
sudo apt-get -q -q install $build_deps >> $build_path/build.pfring.log 2>&1

# PF_RING
# ------------------------------------------------------------------------------
# 
echo -e " [1m*[0m Grabing PF_RING:$git_pfring_version"
cd $build_path
git clone -q $git_pfring
( cd $build_path/PF_RING && git checkout $git_pfring_version )

# Prepare PF_RING
# ------------------------------------------------------------------------------
#
echo -e " [1m*[0m Configuring PF_RING: $build_path/build.pfring.log"
pf_ring_version=`grep "RING_VERSION " 	PF_RING/kernel/linux/pf_ring.h | awk -F\" {'print $2'}`
# Lets go for ubuntu build
cd $build_path/PF_RING/package/ubuntu
# configure expects that PF_RING is in $HOME
HOME=$build_path ./configure >> $build_path/build.pfring.log
# no signing yet
sed -i "s/dpkg-sig/#dpkg-sig/" Makefile

# Build PF_RING lib
# ------------------------------------------------------------------------------
cd $build_path/PF_RING/userland
debbuild_helper lib "High-speed packet capture, filtering and analysis"
debbuild_helper libpcap "System interface for user-level packet capture, with PF_RING support" "" "libpcap0.8" "libpcap0.8-dev" "libpcap" "libpcap-dev"

# PF_RING libs are needed for PF_RING modules and Suricata
sudo apt-get -q -q install `find $build_path -name pfring-lib_*_amd64.deb` >> $build_path/build.suricata.log
# remove conflicts
sudo dpkg -r tcpdump libpcap0.8 libpcap0.8-dev libpcap-dev libpcap >> $build_path/build.suricata.log 2>&1
sudo apt-get -q -q install `find $build_path -name pfring-libpcap_*_amd64.deb` >> $build_path/build.suricata.log

debbuild_helper tcpdump "command-line network traffic analyzer, with PF_RINT support" "nocheck" "tcpdump"

# build PF_RING dkms
# ------------------------------------------------------------------------------
#
echo -e " [1m*[0m Building PF_RING: $build_path/build.pfring.log"

cd $build_path/PF_RING/package/ubuntu
make all 2>&1 | pv -p -t -l -s 740 -  >> $build_path/build.pfring.log

cd $build_path/PF_RING/kernel
sudo make -f Makefile.dkms deb >> $build_path/build.pfring.log 2>&1
find /var/lib/dkms/pfring/ -name "pfring-dkms*.deb" -exec cp \{\} $build_path \;

# migrate debs
find $build_path/PF_RING -name "*.deb" -exec mv \{\} $build_path \;

# Build Suricata
# ------------------------------------------------------------------------------
cd $build_path

echo -e " \e[1m*\e[0m Grabing suricata"
wget -q -O - $url_suricata | tar xz

echo -e " [1m*[0m Configuring Suricata"
cd $build_path/suricata-${version}
rm libhtp -rf && git clone -q $git_libhtp
(cd libhtp && ./autogen.sh 2>&1 && ./configure ) >> $build_path/build.suricata.log

echo -e " [1m*[0m Building Suricata"
dh_make -y -c gpl2 -n -s >> $build_path/build.suricata.log
# https://redmine.openinfosecfoundation.org/projects/suricata/wiki/Installation_from_GIT_with_PF_RING_on_Ubuntu_server_1204
sed -i "s/%:/export DEB_LDFLAGS_MAINT_APPEND = -lrt -lnuma\n\n%:/" debian/rules
echo -e "override_dh_auto_configure:\n\t dh_auto_configure -- --enable-nfqueue --enable-pfring --with-libpfring-includes=$build_path/PF_RING/kernel --with-libpfring-libraries=/usr/lib --disable-gccmarch-native\n" >> debian/rules

# add pfring to deps for automatic installation
sed -i "s/^\(Depends:.*\)$/\\1, pfring-lib, pfring-dkms/" debian/control
sed -i '/^Homepage:/c Homepage: https://suricata-ids.org' debian/control
sed -i '/^Description:/c Description: Suricata open source multi-thread IDS/IPS.' debian/control
sed -i 's/.*insert long description.*/ Suricata is a free and open source, mature, fast and robust network threat detection engine/' debian/control

# Upstart init script

cat > suricata.service <<EOF
[Unit]
Description=Suricata Intrusion Detection Service
After=syslog.target network-online.target

[Service]
EnvironmentFile=-/etc/default/suricata
Restart=always
TimeoutStartSec=8
RestartSec=8
ExecStartPre=/bin/rm -f /var/run/suricata.pid
ExecStart=/usr/bin/suricata -c /etc/suricata/suricata.yaml --pidfile /var/run/suricata.pid \$OPTIONS
ExecReload=/bin/kill -USR2 $MAINPID

[Install]
WantedBy=multi-user.target
EOF

mkdir -p default
cat > default/suricata <<EOF
OPTIONS="-i eth0 --user daemon --group daemon"
EOF

# Add configuration files, which seem to be missing from Makefile install section
cat > debian/install <<EOF
default/suricata etc/default/
suricata.service etc/systemd/system
suricata.yaml etc/suricata/
classification.config etc/suricata/
reference.config etc/suricata/
threshold.config etc/suricata/
rules/ etc/suricata/
EOF
cat > debian/postinst <<EOF
#!/bin/sh
# postinst script for suricata
#
# see: dh_installdeb(1)

set -e
mkdir -p /var/log/suricata
chown daemon.daemon /var/log/suricata/

mkdir -p /var/run/suricata
chown daemon.daemon /var/run/suricata/

wget -qO - https://rules.emergingthreats.net/open/suricata-3.0/emerging.rules.tar.gz | tar -x -z -C "/etc/suricata" -f -

systemctl enable suricata

exit 0
EOF
cat > debian/postrm <<EOF
#!/bin/sh

set -e
rm -rf /var/lib/suricata
exit 0
EOF

rm debian/{*.ex,*.EX}

dpkg-buildpackage -j32 -us -uc -rfakeroot 2>&1 | pv -p -t -l -s 1600 - >> $build_path/build.suricata.log

# mkdir /var/log/suricata

echo "---"
cd $build_path
pwd
ls -la *.deb
echo "---"

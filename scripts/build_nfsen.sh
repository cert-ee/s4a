#!/bin/bash

build_path=`pwd`"/nfsen-build"
mkdir -p ${build_path}
cd ${build_path}

pkg_name="nfsen"
nfsen_version="1.3.8"
pkg_version="${nfsen_version}-8"
nfsen=$pkg_name"-"$nfsen_version

sudo apt-get -q -q install librrds-perl nfdump fakeroot libmailtools-perl libsocket6-perl
rm -rf ${build_path}/${nfsen} ${build_path}/install
wget -q https://downloads.sourceforge.net/project/nfsen/stable/$nfsen/$nfsen.tar.gz
tar xfz $nfsen.tar.gz

cd $nfsen
cat etc/nfsen-dist.conf | sed "s|^\$BASEDIR.*|\$BASEDIR = \"${build_path}/install/\";|" > etc/nfsen.conf
sed -i "s|^\$BINDIR=.*|\$BINDIR=\"${build_path}/install/usr/bin\";|" etc/nfsen.conf
sed -i "s|^\$HTMLDIR *=.*|\$HTMLDIR=\"${build_path}/install/var/www/nfsen/\";|" etc/nfsen.conf
sed -i "s|^\$PREFIX.*|\$PREFIX=\"/usr/bin\";|" etc/nfsen.conf
sed -i "s|^\$LIBEXECDIR=.*|\$LIBEXECDIR=\"${build_path}/install/usr/local/nfsen/libexec\";|" etc/nfsen.conf
sed -i "s|^\$BACKEND_PLUGINDIR.*|\$BACKEND_PLUGINDIR = \"${build_path}/install/usr/local/nfsen/plugins\";|" etc/nfsen.conf
sed -i "s|^\$PROFILEDATADIR=.*|\$PROFILEDATADIR=\"${build_path}/install/srv/nfsen/profiles-data\";|" etc/nfsen.conf
sed -i "s|^\$PROFILESTATDIR=.*|\$PROFILESTATDIR=\"${build_path}/install/srv/nfsen/profiles-stat\";|" etc/nfsen.conf
sed -i "s|^\$USER.*|\$USER=\"`whoami`\";|" etc/nfsen.conf
sed -i "s|^\$WWWUSER.*|\$WWWUSER=\"`whoami`\";|" etc/nfsen.conf
sed -i "s|^\$WWWGROUP.*|\$WWWGROUP=\"`whoami`\";|" etc/nfsen.conf
sed -i "s|^[# ]*\$PIDDIR.*|\$PIDDIR=\"${build_path}/install/var/run/nfsend\";|" etc/nfsen.conf
sed -i "s|^[# ]*\$COMMSOCKET.*|\$COMMSOCKET=\"${build_path}/install/\$PIDDIR/nfsend.comm\";|" etc/nfsen.conf

mkdir -p ${build_path}/install
echo "" | sudo ./install.pl etc/nfsen.conf >/dev/null 2>&1

sudo chown -R `id -u`:`id -g` ${build_path}/install

cd ${build_path}/install

cat etc/nfsen-dist.conf | sed "s|^\$BASEDIR.*|\$BASEDIR = \"/\";|" > etc/nfsen.conf
sed -i "s|^\$BINDIR=.*|\$BINDIR=\"/usr/bin\";|" etc/nfsen.conf
sed -i "s|^\$HTMLDIR=.*|\$HTMLDIR=\"/var/www/nfsen/\";|" etc/nfsen.conf
sed -i "s|^\$PREFIX.*|\$PREFIX=\"/usr/bin\";|" etc/nfsen.conf
sed -i "s|^[# ]*\$PIDDIR.*|\$PIDDIR=\"/var/run/nfsend\";|" etc/nfsen.conf
sed -i "s|^[# ]*\$COMMSOCKET.*|\$COMMSOCKET=\"\$PIDDIR/nfsend.comm\";|" etc/nfsen.conf
sed -i "s|^\$LIBEXECDIR=.*|\$LIBEXECDIR=\"/usr/local/nfsen/libexec\";|" etc/nfsen.conf
sed -i "s|^\$BACKEND_PLUGINDIR.*|\$BACKEND_PLUGINDIR = \"/usr/local/nfsen/plugins\";|" etc/nfsen.conf
sed -i "s|^\$PROFILEDATADIR=.*|\$PROFILEDATADIR=\"/srv/nfsen/profiles-data\";|" etc/nfsen.conf
sed -i "s|^\$PROFILESTATDIR=.*|\$PROFILESTATDIR=\"/srv/nfsen/profiles-stat\";|" etc/nfsen.conf
sed -i "s|^\$USER.*|\$USER = \"netflow\";|" etc/nfsen.conf
sed -i "s|^\$WWWUSER.*|\$WWWUSER = \"www-data\";|" etc/nfsen.conf
sed -i "s|^\$WWWGROUP.*|\$WWWGROUP = \"www-data\";|" etc/nfsen.conf
sed -i "s|${build_path}/install||g" usr/local/nfsen/libexec/NfConf.pm usr/bin/RebuildHierarchy.pl usr/bin/testPlugin usr/bin/nfsen usr/bin/nfsend var/www/nfsen/conf.php

mkdir -p ${build_path}/install/DEBIAN
cat > ${build_path}/install/DEBIAN/control <<EOF
Package: $pkg_name
Version: $pkg_version
Section: network
Priority: optional
Architecture: amd64
Depends: adduser, librrds-perl, nfdump, libsocket6-perl, libmailtools-perl
Maintainer: autobot
Description: NfSen is a graphical web based front end for the nfdump netflow tools.
EOF
cat > ${build_path}/install/DEBIAN/postinst <<EOF
#!/bin/bash
set -e

addgroup --system --quiet netflow
adduser --system --quiet --no-create-home --ingroup netflow netflow
adduser --quiet --add_extra_groups netflow www-data

touch /srv/nfsen/profiles-stat/hints

chown -R root:www-data /var/www/nfsen/ /usr/local/nfsen/libexec /usr/local/nfsen/plugins  /etc/{nfsen.conf,nfsen-dist.conf}
chown -R root:www-data /var/www/nfsen/*
chown -R netflow:www-data /var/{filters,fmt} /srv/nfsen/profiles-data /srv/nfsen/profiles-stat /var/run/nfsend

echo "Enable & start nfsen"
systemctl enable nfsen
systemctl restart nfsen

EOF
cat > ${build_path}/install/DEBIAN/prerm <<EOF
#!/bin/bash

echo "Disable & stop nfsen"
systemctl disable nfsen
systemctl stop nfsen
rm -rf /srv/nfsen/profiles-stat/hints

EOF

cat > ${build_path}/install/DEBIAN/postrm <<EOF
#!/bin/bash
set -e

deluser --system --quiet  netflow

EOF
mkdir -p ${build_path}/install/etc/systemd/system
cat > ${build_path}/install/etc/systemd/system/nfsen.service <<EOF
[Unit]
Description=NfSen Service
After=network.target

[Service]
Type=forking
PIDFile=/var/run/nfsend/nfsend.pid
ExecStartPre=-/bin/bash -c '/bin/mkdir -p /var/run/nfsend; /bin/chown netflow:www-data /var/run/nfsend'
ExecStart=/usr/bin/nfsen start
ExecStop=/usr/bin/nfsen stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

chmod a+rx DEBIAN/*
cd ${build_path}
fakeroot dpkg-deb  --build ${build_path}/install/ ${pkg_name}_${pkg_version}.deb

ls -la `pwd`/${pkg_name}_${pkg_version}.deb

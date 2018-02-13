#!/bin/bash

my_path=`pwd`

# Essential build requirements|  (pbuilder cmake ?)
sudo apt-get -q -q install build-essential dh-make dh-systemd dh-autoreconf pv >> ${my_path}/netdata.build.log
# Requirements from:
# - https://github.com/firehol/netdata/wiki/Installation
sudo apt-get -q -q install zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autoconf-archive autogen automake pkg-config curl >> ${my_path}/netdata.build.log

rm -rf netdata
#git clone https://github.com/firehol/netdata.git --depth=1 >> ${my_path}/netdata.build.log 2>&1
# tmp workaround until pull request has been approved
git clone https://github.com/voldemarpanso/netdata.git >> ${my_path}/netdata.build.log 2>&1

cd netdata
# tmp workaround until pull request has been approved
git checkout fix_deb_pkg_scripting
echo -e " [1m*[0m Configuring Netdata"
./autogen.sh > ${my_path}/netdata.build.log 2>&1 && ./configure >> ${my_path}/netdata.build.log 2>&1
# buildpackage configuration
ln -s contrib/debian ./debian
# fix relocation script
sed -i "s/-maxdepth 1 -type d -printf/-maxdepth 1 -type f -printf/" debian/rules

# Apparently netdata has issues with links, seems to be bug
# adding some adjustments to installation
sed -i "s/ln -s \"\/usr\/share\/netdata\//cp -ar \"\$\(TOP\)\/usr\/share\/netdata\//" debian/rules
sed -i "s/\(chown -R root:netdata \/usr\/share\/netdata\/\*\)/\\1\n\tchown -R root:netdata \/var\/lib\/netdata\/www\/*/" debian/netdata.postinst.in

# create changelog
DATE=`date -R`
cat > debian/changelog <<EOF
netdata (1.6.1) unstable; urgency=medium

  * Rolling Release.
  
   -- root <automake@auto.bots>  $DATE
EOF
# enable debug for dpkg-buildpackage
# sed -i "s/^\(TOP.*\)/\\1\nexport DH_VERBOSE = 1/" debian/rules

echo -e " [1m*[0m Building Netdata: $HOME/netdata.build.log"
dpkg-buildpackage -us -uc -rfakeroot 2>&1 | pv -p -t -l -s 750 >> ${my_path}/netdata.build.log

VERSION=`grep PACKAGE_VERSION config.h | awk '{ print $NF }' | tr -d '"_a-z'`

echo -e "\n---"
ls -la ${my_path}/netdata_*
echo "---"

echo "sudo dpkg -i ${my_path}/netdata_${VERSION/_/\~}_amd64.deb "
echo "dpkg -L netdata"

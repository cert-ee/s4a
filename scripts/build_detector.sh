#!/bin/bash

git_repo="git@github.com:cert-ee/s4a-detector.git"
pkg_name="s4a-detector"

build_path=`pwd`/$pkg_name

rm -rf $pkg_name
mkdir -p $build_path
cd $build_path

# Install dependencies
sudo add-apt-repository "deb https://deb.nodesource.com/node_8.x xenial main"
wget -q -O /tmp/nodesource.gpg.key https://deb.nodesource.com/gpgkey/nodesource.gpg.key
sudo apt-key add /tmp/nodesource.gpg.key
sudo apt-get update
sudo apt-get install -q -y jq nodejs dpkg fakeroot
nodejs_version=`nodejs -v | sed "s/[v\.]\+//g"`
if [ $nodejs_version -lt 800 ] ; then
	echo "Sorry, at least nodejs 8 is required"
	exit
fi
npm install node-deb 2>/dev/null

git clone $git_repo

cd $build_path/$pkg_name/
# no need for git data
rm -rf .git
$build_path/node_modules/node-deb/node-deb --install-strategy npm-install -- .
mv s4a*deb $build_path

cd $build_path
ls -la $build_path/*.deb

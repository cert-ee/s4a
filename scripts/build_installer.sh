#!/bin/bash

echo -e "\n[1m* Installing dependencies[0m"
sudo apt-get -q -y install makeself gettext

if [ -d installer/ ] ; then
	echo -e "\n[1m* Compiling new script[0m"
	# rebuild message object files
	msgfmt -o installer/locale/en/LC_MESSAGES/en.mo installer/locale/en/LC_MESSAGES/detector.po
	msgfmt -o installer/locale/et/LC_MESSAGES/et.mo installer/locale/et/LC_MESSAGES/detector.po

	# move out of the way :)
	mv installer/locale/en/LC_MESSAGES/detector.po /tmp/detector.en.po
	mv installer/locale/et/LC_MESSAGES/detector.po /tmp/detector.et.po

	makeself --xz installer/ install_detector.sh "Detector installer" ./install_detector.sh
	md5sum ./install_detector.sh > ./install_detector.sh.md5

	# move back :)
	mv /tmp/detector.en.po installer/locale/en/LC_MESSAGES/detector.po
	mv /tmp/detector.et.po installer/locale/et/LC_MESSAGES/detector.po

	echo "[1m* Done: [0m"
	ls -la install_detector.sh install_detector.sh.md5

else
	echo "[1m!!! Installer script data not found[0m"
fi

#!/bin/sh

repo_url=https://repo.s4a.cert.ee

cd /data/moloch/etc
/bin/rm -f ipv4-address-space.csv
/usr/bin/wget -nv "$repo_url/geoip/ipv4-address-space.csv"

/bin/rm -f GeoLite2-Country.mmdb
/usr/bin/wget -nv "$repo_url/geoip/GeoLite2-Country.mmdb"

/bin/rm -f GeoLite2-ASN.mmdb
/usr/bin/wget -nv "$repo_url/geoip/GeoLite2-ASN.mmdb"

/bin/rm oui.txt
/usr/bin/wget -nv "$repo_url/geoip/oui.txt"

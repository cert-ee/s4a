---
detector_update_geoip_sh:
  file.managed:
    - name: /usr/local/sbin/update_geoip.sh
    - source: salt://{{ slspath }}/files/geoip/update_geoip.sh.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja

detector_geoip_cron:
  cron.present:
    - name: /usr/local/sbin/update_geoip.sh restart > /dev/null 2>&1
    - user: root
    - minute: 5
    - hour: '0'
    - dayweek: '*/3'
    - require:
        - file: detector_update_geoip_sh

geoip_dir:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: true
    - names:
        - /srv/s4a-detector/geoip

run_update_geoip:
  cmd.run:
    - name: /usr/local/sbin/update_geoip.sh > /dev/null
    - cwd: /usr/local/sbin
    - runas: root

{% if salt['file.directory_exists' ]('/opt/arkime') %}
remove_arkime_geoip_leftovers:
  file.absent:
    - names:
        - /opt/arkime/etc/GeoLite2-Country.mmdb
        - /opt/arkime/etc/GeoLite2-ASN.mmdb
        - /opt/arkime/etc/ipv4-address-space.csv
        - /opt/arkime/etc/oui.txt
        - /opt/arkime/etc/GeoLite2-City.mmdb

/opt/arkime/etc/GeoLite2-Country.mmdb:
  file.symlink:
    - target: /srv/s4a-detector/geoip/GeoLite2-Country.mmdb

/opt/arkime/etc/GeoLite2-ASN.mmdb:
  file.symlink:
    - target: /srv/s4a-detector/geoip/GeoLite2-ASN.mmdb

/opt/arkime/etc/ipv4-address-space.csv:
  file.symlink:
    - target: /srv/s4a-detector/geoip/ipv4-address-space.csv

/opt/arkime/etc/oui.txt:
  file.symlink:
    - target: /srv/s4a-detector/geoip/oui.txt
{% endif %}

remove_arkime_legacy_geoip_cron:
  cron.absent:
    - name: /opt/arkime/bin/arkime_update_geo.sh > /dev/null 2>&1
    - user: root
    - minute: 5
    - hour: '0'
    - dayweek: '*/3'

remove_evebox_geoip_leftovers:
  file.absent:
    - names:
        - /etc/evebox/GeoLite2-City.mmdb

/etc/evebox/GeoLite2-City.mmdb:
  file.symlink:
    - target: /srv/s4a-detector/geoip/GeoLite2-City.mmdb

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
    - name: /usr/local/sbin/update_geoip.sh > /dev/null 2>&1
    - user: root
    - minute: 5
    - hour: '0'
    - dayweek: '*/3'
    - require:
      - file: detector_update_geoip_sh

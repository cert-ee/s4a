detector_timesyncd_service:
  service.running:
    - name: systemd-timesyncd
    - full_restart: true
    - watch:
      - file: detector_timesyncd_conf
    - enable: true

detector_timesyncd_conf:
  file.managed:
    - name: /etc/systemd/timesyncd.conf
    - source: salt://{{ slspath }}/files/timesyncd/timesyncd.conf
    - mode: 644
    - template: jinja

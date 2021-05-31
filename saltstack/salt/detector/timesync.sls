{% set ntp_conf = salt['file.file_exists']('/etc/ntp.conf') %}
{% set chrony_conf = salt['file.file_exists']('/etc/chrony/chrony.conf') %}
{% if (ntp_conf or chrony_conf) == False %}
detector_timesyncd_conf:
  file.managed:
    - name: /etc/systemd/timesyncd.conf
    - source: salt://{{ slspath }}/files/timesyncd/timesyncd.conf
    - mode: 644
    - template: jinja

detector_timesyncd_service:
  service.running:
    - name: systemd-timesyncd
    - full_restart: true
    - watch:
      - file: detector_timesyncd_conf
    - enable: true
{% endif %}

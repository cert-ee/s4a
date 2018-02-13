detector_ntp_pkg:
  pkg.installed:
    - name: ntp
    - refresh: true

detector_ntp_service:
  service.running:
    - name: ntp
    - reload: true
    - watch:
      - pkg: detector_ntp_pkg
      - file: detector_ntp_conf
    - enable: true

detector_ntp_conf:
  file.managed:
    - name: /etc/ntp.conf
    - source: salt://{{ slspath }}/files/ntp/ntp.conf
    - mode: 644
    - require:
      - pkg: detector_ntp_pkg

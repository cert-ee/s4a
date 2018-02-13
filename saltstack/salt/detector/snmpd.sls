detector_snmpd_pkg:
  pkg.installed:
    - name: snmpd
    - refresh: true

detector_snmpd_service:
  service.running:
    - name: snmpd
    - watch:
      - file: detector_snmpd_conf
      - pkg: detector_snmpd_pkg

detector_snmpd_conf:
  file.managed:
    - name: /etc/snmp/snmpd.conf
    - source: salt://{{ slspath }}/files/snmpd/snmpd.conf
    - mode: 644
    - user: root
    - group: root
    - require:
      - pkg: detector_snmpd_pkg

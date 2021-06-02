include:
  - detector.deps

netdata_conf:
  file.managed:
    - name: /etc/netdata/netdata.conf
    - source: salt://{{ slspath }}/files/netdata/netdata.conf
    - watch:
      - pkg: netdata

netdata_plugins_conf:
  file.managed:
    - name: /etc/netdata/python.d.conf
    - source: salt://{{ slspath }}/files/netdata/python.d.conf
    - watch:
      - pkg: netdata

netdata_dirs:
  file.directory:
    - user: netdata
    - group: netdata
    - makedirs: false
    - names:
      - /var/lib/netdata
    - recurse:
      - user
      - group
    - require:
      - pkg: netdata

netdata:
  pkg.installed:
    - version: 1.6.1
    - hold: true
    - update_holds: true
    - refresh: true
    - require:
        - pkgrepo: s4a_repo
  service.running:
    - enable: true
    - full_restart: true
    - watch:
      - pkg: netdata
      - file: netdata_conf

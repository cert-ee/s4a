purge_old_netdata_pkg:
  cmd.run:
    - name: apt-mark unhold netdata
  service.dead:
    - name: netdata
    - enable: false
  pkg.purged:
    - name: netdata

netdata_pkg:
  cmd.run:
    - name: apt-mark unhold netdata-core
  pkg.installed:
    - name: netdata
    - version: 1.19.0-3ubuntu1
    - hold: true
    - update_holds: true
    - refresh: true

netdata-core_pkg:
  cmd.run:
    - name: apt-mark unhold netdata-core
  pkg.installed:
    - name: netdata-core
    - version: 1.19.0-3ubuntu1
    - hold: true
    - update_holds: true
    - refresh: true

netdata_service_stop:
  service.dead:
    - name: netdata

netdata_group:
  group.present:
    - name: netdata
    - system: true

netdata_user:
  user.present:
    - name: netdata
    - fullname: Netdata
    - system: true
    - shell: /bin/false
    - home: /var/lib/netdata
    - groups:
      - netdata
    - watch:
      - group: netdata

netdata_conf:
  file.managed:
    - name: /etc/netdata/netdata.conf
    - source: salt://{{ slspath }}/files/netdata/netdata.conf
    - watch:
      - pkg: netdata-core_pkg

netdata_plugins_conf:
  file.managed:
    - name: /etc/netdata/python.d.conf
    - source: salt://{{ slspath }}/files/netdata/python.d.conf
    - watch:
      - pkg: netdata-core_pkg

netdata_dirs:
  file.directory:
    - user: netdata
    - group: netdata
    - makedirs: false
    - names:
      - /var/lib/netdata
      - /usr/share/netdata
    - recurse:
      - user
      - group
    - require:
      - pkg: netdata-core_pkg

#netdata_service_start:
#  service.running:
#    - name: netdata
#    - enable: true
#    - full_restart: true

netdata_service_start:
  cmd.run:
    - name: systemctl restart netdata
    - runas: root

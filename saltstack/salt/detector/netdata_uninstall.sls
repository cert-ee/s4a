netdata_pkg:
  cmd.run:
    - name: |
        apt-mark unhold netdata-core
        apt-mark unhold netdata
  service.dead:
    - name: netdata
    - enable: false
  pkg.purged:
    - pkgs:
      - netdata
      - netdata-core

netdata:
  user.absent:
    - purge: True
    - force: True

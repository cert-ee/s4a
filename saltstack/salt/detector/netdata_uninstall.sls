netdata_pkg:
  cmd.run:
    - name: apt-mark unhold netdata
  service.dead:
    - name: netdata
    - enable: false
  pkg.purged:
    - name: netdata

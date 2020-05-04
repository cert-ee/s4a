detector_kibana_pkg:
  service.dead:
    - name: kibana
    - enable: false
  cmd.run:
    - name: apt-mark unhold kibana
  pkg.purged:
    - name: kibana

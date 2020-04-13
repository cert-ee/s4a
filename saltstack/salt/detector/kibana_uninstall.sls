detector_kibana_pkg:
  service.dead:
    - name: kibana
    - enable: false
  pkg.purged:
    - name: kibana

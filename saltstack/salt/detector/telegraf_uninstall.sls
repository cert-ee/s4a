detector_telegraf_pkg:
  service.dead:
    - name: telegraf
    - enable: false
  pkg.purged:
    - name: telegraf

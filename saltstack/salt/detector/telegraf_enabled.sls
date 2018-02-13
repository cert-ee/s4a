detector_telegraf_service:
  service.running:
    - name: telegraf
    - enable: true
    - reload: true

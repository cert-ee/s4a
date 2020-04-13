detector_kibana_service:
  service.running:
    - name: kibana
    - enable: true
    - reload: true

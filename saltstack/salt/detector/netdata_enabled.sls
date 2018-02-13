netdata_svc_enabled:
  service.enabled:
    - name: netdata

netdata_svc:
  service.running:
    - name: netdata
    - reload: true

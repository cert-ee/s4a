
nfsen_svc:
  service.running:
    - name: nfsen
    - full_restart: true
    - enable: true

fprobe_svc:
  service.running:
    - name: fprobe
    - reload: true
    - enable: true

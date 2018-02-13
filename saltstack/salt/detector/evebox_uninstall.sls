evebox_service:
  service.dead:
    - names:
       - evebox
       - evebox-agent
    - enable: false

evebox_pkg:
  pkg.purged:
    - name: evebox
  watch:
    - service: evebox_service

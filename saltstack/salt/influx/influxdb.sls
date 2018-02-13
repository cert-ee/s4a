include:
  - influx.repo

influxdb:
  pkg.installed:
    - refresh: True
    - require:
      - pkgrepo: influxdata_repo
  service.running:
    - enable: True



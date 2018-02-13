include:
  - influx.repo

telegraf:
  pkg.installed:
    - refresh: True
    - require:
      - pkgrepo: influxdata_repo
  service.running:
    - enable: True

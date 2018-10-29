include:
  - influx.repo

central_chronograf_pkg:
  pkg.installed:
    - name: chronograf
    - refresh: true
    - require:
      - pkgrepo: influxdata_repo

central_chronograf_service:
  service.running:
    - name: chronograf
    - watch:
      - pkg: central_chronograf_pkg
      - file: central_chronograf_conf
    - enable: true

central_chronograf_conf:
  file.managed:
    - name: /etc/default/chronograf
    - source: salt://{{ slspath }}/files/chronograf/chronograf.jinja
    - user: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja
    - require:
      - pkg: central_chronograf_pkg


include:
  - detector.deps

kibana:
  pkg.installed:
    - refresh: true
    - require:
        - pkgrepo: elastic5x_repo
  service.running:
    - name: kibana
    - enable: true
    - watch:
      - pkg: kibana
      - file: detector_kibana_yaml

detector_kibana_yaml:
  file.managed:
    - name: /etc/kibana/kibana.yml
    - source: salt://{{ slspath }}/files/kibana/kibana.yml
    - user: root
    - group: root
    - mode: 644

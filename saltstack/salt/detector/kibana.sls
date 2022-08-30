{% set kibana_index_status = salt['cmd.run'](cmd='curl -s -XGET http://localhost:9200/_cat/indices | grep kibana -c', python_shell=True) %}

include:
  - detector.deps

detector_kibana_pkg:
  cmd.run:
    - name: apt-mark unhold kibana
  pkg.installed:
    - name: kibana
    - version: 7.17.6
    - hold: true
    - update_holds: true
    - refresh: true
    - require:
      - pkgrepo: elastic7x_repo

detector_kibana_conf:
  file.managed:
    - name: /etc/kibana/kibana.yml
    - source: salt://{{ slspath }}/files/kibana/kibana.yml

detector_kibana_logrotate:
  file.managed:
    - name: /etc/logrotate.d/kibana
    - source: salt://{{ slspath }}/files/kibana/kibana_logrotate
    - user: root
    - group: root
    - mode: 644

{% if kibana_index_status == "0" %}
elasticdump:
  npm.installed:
    - name: elasticdump

detector_kibana_dashboard_index_mapping:
  file.managed:
    - name: /etc/kibana/s4a-kibana-v7.16-mapping.json
    - source: salt://{{ slspath }}/files/kibana/s4a-kibana-v7.16-mapping.json
  cmd.run:
    - name: elasticdump --quiet --input=/etc/kibana/s4a-kibana-v7.16-mapping.json --output=http://localhost:9200/.kibana --type=mapping

detector_kibana_dashboard_index_data:
  file.managed:
    - name: /etc/kibana/s4a-kibana-v7.16-data.json
    - source: salt://{{ slspath }}/files/kibana/s4a-kibana-v7.16-data.json
  cmd.run: 
    - name: elasticdump --quiet --input=/etc/kibana/s4a-kibana-v7.16-data.json --output=http://localhost:9200/.kibana --type=data
{% endif %}

detector_kibana_service:
  service.running:
    - name: kibana
    - watch:
      - pkg: detector_kibana_pkg
      - file: detector_kibana_conf
    - enable: true
    - full_restart: true

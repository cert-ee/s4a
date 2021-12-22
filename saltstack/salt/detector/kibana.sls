{% set kibana_index_status = salt['cmd.run'](cmd='curl -s -XGET http://localhost:9200/.kibana | jq .status', python_shell=True) %}

{% if kibana_index_status == "404" %}
include:
  - detector.deps

detector_kibana_pkg:
  cmd.run:
    - name: apt-mark unhold kibana
  pkg.installed:
    - name: kibana
    - version: 7.15.1
    - hold: true
    - update_holds: true
    - refresh: true
    - require:
      - pkgrepo: elastic7x_repo

detector_kibana_conf:
  file.managed:
    - name: /etc/kibana/kibana.yml
    - source: salt://{{ slspath }}/files/kibana/kibana.yml

elasticdump:
  npm.installed:
    - name: elasticdump

detector_kibana_dashboard_index_mapping:
  file.managed:
    - name: /etc/kibana/s4a-kibana-v7.15-mapping.json
    - source: salt://{{ slspath }}/files/kibana/s4a-kibana-v7.15-mapping.json
  cmd.run:
    - name: elasticdump --quiet --input=/etc/kibana/s4a-kibana-v7.15-mapping.json --output=http://localhost:9200/.kibana --type=mapping

detector_kibana_dashboard_index_data:
  file.managed:
    - name: /etc/kibana/s4a-kibana-v7.15-data.json
    - source: salt://{{ slspath }}/files/kibana/s4a-kibana-v7.15-data.json
  cmd.run: 
    - name: elasticdump --quiet --input=/etc/kibana/s4a-kibana-v7.15-data.json --output=http://localhost:9200/.kibana --type=data
{% else %}
kibana_skip_installation:
  cmd.run:
    - name: echo "Kibana exists. Not installing."
{% endif %}

detector_kibana_service:
  service.running:
    - name: kibana
#    - watch:
#      - pkg: detector_kibana_pkg
#      - file: detector_kibana_conf
    - enable: true
    - full_restart: true

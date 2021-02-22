{% set kibana_1_index_status = salt['cmd.run'](cmd='curl -s -XGET http://localhost:9200/.kibana_1 | jq .status', python_shell=True) %}
{% set kibana_index_status = salt['cmd.run'](cmd='curl -s -XGET http://localhost:9200/.kibana | jq .status', python_shell=True) %}

include:
  - detector.deps
#  - detector.elastic

detector_kibana_pkg:
  cmd.run:
    - name: apt-mark unhold kibana
  pkg.installed:
    - name: kibana
    - version: 7.10.2
    - hold: true
    - update_holds: true
    - refresh: true
    - require:
#      - pkg: elasticsearch
      - pkgrepo: elastic7x_repo

detector_kibana_conf:
  file.managed:
    - name: /etc/kibana/kibana.yml
    - source: salt://{{ slspath }}/files/kibana/kibana.yml

{% if kibana_index_status == "404" or kibana_1_index_status == "404"%}

detector_kibana_delete_old_index:
  http.query:
    - name: 'http://localhost:9200/.kibana'
    - method: DELETE
    - status:
      - 200
      - 404
    - status_type: list
    - header_dict:
        Content-Type: "application/json"

elasticdump:
  npm.installed:
    - name: elasticdump

detector_kibana_dashboard_index_mapping:
  file.managed:
    - name: /etc/kibana/s4a-kibana-v7-mapping.json
    - source: salt://{{ slspath }}/files/kibana/s4a-kibana-v7-mapping.json
  cmd.run:
    - name: elasticdump --quiet --input=/etc/kibana/s4a-kibana-v7-mapping.json --output=http://localhost:9200/.kibana --type=mapping

detector_kibana_dashboard_index_data:
  file.managed:
    - name: /etc/kibana/s4a-kibana-v7-data.json
    - source: salt://{{ slspath }}/files/kibana/s4a-kibana-v7-data.json
  cmd.run: 
    - name: elasticdump --quiet --input=/etc/kibana/s4a-kibana-v7-data.json --output=http://localhost:9200/.kibana --type=data
{% endif %}

detector_kibana_service:
  service.running:
    - name: kibana
    - watch:
      - pkg: detector_kibana_pkg
      - file: detector_kibana_conf
    - enable: true
    - full_restart: true

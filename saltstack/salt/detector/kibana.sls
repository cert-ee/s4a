kibana:
  pkg.installed:
    - version: 6.8.7
    - hold: true
    - update_holds: true
    - refresh: true

kibana_dirs:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: true
    - names:
      - /etc/kibana

kibana_conf:
  file.managed:
    - name: /etc/kibana/kibana.yml
    - source: salt://{{ slspath }}/files/kibana/kibana.yml

{% if not salt['file.file_exists' ]('/etc/kibana/s4a-kibana-v6-mapping.json') %}

elasticdump:
  npm.installed:
    - name: elasticdump

kibana_dashboard_index_mapping:
  file.managed:
    - name: /etc/kibana/s4a-kibana-v6-mapping.json
    - source: salt://{{ slspath }}/files/kibana/s4a-kibana-v6-mapping.json
  cmd.run:
    - name: elasticdump --quiet --input=/etc/kibana/s4a-kibana-v6-mapping.json --output=http://localhost:9200/kibana --type=mapping

kibana_dashboard_index_data:
  file.managed:
    - name: /etc/kibana/s4a-kibana-v6-data.json
    - source: salt://{{ slspath }}/files/kibana/s4a-kibana-v6-data.json
  cmd.run: 
    - name: elasticdump --quiet --input=/etc/kibana/s4a-kibana-v6-data.json --output=http://localhost:9200/kibana --type=data
{% endif %}

kibana_service_enabled:
  service.enabled:
    - names:
       - kibana

kibana_service:
  service.running:
    - names:
       - kibana
    - full_restart: true
    - watch:
      - pkg: kibana
      - file: kibana_conf
      - service: kibana_service_enabled

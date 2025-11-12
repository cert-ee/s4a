{% set elastic_version_installed = salt['pkg.version']('elasticsearch') %}
{% set elastic_tls = salt['cmd.run'](cmd='curl -sk https://127.0.0.1:9200/_cluster/health|jq .number_of_nodes', python_shell=True) %}

{% if elastic_tls is defined and elastic_tls|int >= 1 %}
{% set elastic_nodes = salt['cmd.run'](cmd='curl -sk https://127.0.0.1:9200/_cluster/health | jq .number_of_nodes', python_shell=True) %}
{% set elastic_status = salt['cmd.run'](cmd='curl -sk https://127.0.0.1:9200/_cluster/health | jq -r .status', python_shell=True) %}
{% set elastic_indices = salt['cmd.run'](cmd='curl -sk https://127.0.0.1:9200/*/_search|jq .hits.total.value', python_shell=True) %}
{% set elastic_deprecationLog = salt['cmd.run'](cmd='curl -sk https://127.0.0.1:9200/.logs-deprecation.elasticsearch-default|jq -r .status', python_shell=True) %}
{% else %}
{% set elastic_nodes = salt['cmd.run'](cmd='curl -s 127.0.0.1:9200/_cluster/health | jq .number_of_nodes', python_shell=True) %}
{% set elastic_status = salt['cmd.run'](cmd='curl -s 127.0.0.1:9200/_cluster/health | jq -r .status', python_shell=True) %}
{% set elastic_indices = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/*/_search|jq .hits.total.value', python_shell=True) %}
{% set elastic_deprecationLog = salt['cmd.run'](cmd='curl -s 127.0.0.1:9200/.logs-deprecation.elasticsearch-default|jq -r .status', python_shell=True) %}
{% endif %}

{% set elastic_data_path_ok = salt['cmd.run'](cmd='if [ -d /srv/elasticsearch ] && [ "$(ls -l /srv/elasticsearch | grep node | grep -o elasticsearch | wc -l)" == "2" ]; then echo True; else echo False; fi', python_shell=True) %}

{% if elastic_version_installed is not defined or not elastic_version_installed or elastic_nodes|int == 1 or elastic_nodes is not defined %}
include:
  - detector.deps

elastic_dependency_pkgs:
  pkg.installed:
    - refresh: true
    - pkgs:
      - python3-elasticsearch

esnode_limits:
  file.append:
    - name: /etc/security/limits.conf
    - text:
      - elasticsearch - nofile 65535
      - elasticsearch - memlock unlimited
      - root - memlock unlimited

elasticsearch:
  cmd.run:
    - name: apt-mark unhold elasticsearch
  pkg.installed:
    - version: 8.19.6
    - hold: true
    - update_holds: true
    - refresh: true
    - require:
      - pkgrepo: elastic8x_repo
      - pkg: dependency_pkgs
  service.dead:
    - name:
      - elasticsearch

elasticsearch_dirs:
  file.directory:
    - user: elasticsearch
    - group: elasticsearch
    - dir_mode: 755
    - file_mode: 644
    - makedirs: true
    - names:
      - /etc/elasticsearch
      - /etc/elasticsearch/scripts
      - /var/log/elasticsearch
      - /var/run/elasticsearch
      - /etc/systemd/system/elasticsearch.service.d
{% if elastic_data_path_ok == "False" %}
      - /srv/elasticsearch
{% endif %}
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: elasticsearch

elasticsearch_yml:
  file.managed:
    - name: /etc/elasticsearch/elasticsearch.yml
    - source: salt://{{ slspath }}/files/elastic/elasticsearch.yml.jinja
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - template: jinja
    - require:
      - file: elasticsearch_dirs

elasticsearch_jvm_options:
  file.managed:
    - name: /etc/elasticsearch/jvm.options
    - source: salt://{{ slspath }}/files/elastic/jvm.options.jinja
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - template: jinja
    - require:
      - file: elasticsearch_dirs
    - watch_in:
      - service: elasticsearch

elasticsearch_log4j2.properties:
  file.managed:
    - name: /etc/elasticsearch/log4j2.properties
    - source: salt://{{ slspath }}/files/elastic/log4j2.properties
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - require:
      - file: elasticsearch_dirs
    - watch_in:
      - service: elasticsearch

elasticsearch_defaults:
  file.managed:
    - name: /etc/default/elasticsearch
    - source: salt://{{ slspath }}/files/elastic/default_elasticsearch.jinja
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - template: jinja

elasticsearch_cron:
  file.managed:
    - name: /etc/cron.daily/elasticsearch
    - source: salt://{{ slspath }}/files/elastic/elasticsearch.cron
    - user: root
    - group: root
    - mode: 750
    - template: jinja

elasticsearch_systemd_override:
  file.managed:
    - name: /etc/systemd/system/elasticsearch.service.d/override.conf
    - source: salt://{{ slspath }}/files/elastic/systemd_override.conf
    - user: root
    - group: root
    - mode: 644

detector_elastic_systemctl_reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: elasticsearch_systemd_override

elasticsearch_service:
  service.running:
    - names:
      - elasticsearch
    - enable: true
    - full_restart: true
    - watch:
      - pkg: elasticsearch
      - file: elasticsearch_yml
      - file: elasticsearch_jvm_options

elasticsearch_allocation_settings:
  file.managed:
    - name: /etc/elasticsearch/allocation_settings.json
    - source: salt://{{ slspath }}/files/elastic/allocation_settings.json
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - require:
      - file: elasticsearch_dirs

elasticsearch_set_allocation_settings:
  http.wait_for_successful_query:
{% if elastic_tls is defined and elastic_tls|int >= 1 %}
    - name: 'https://127.0.0.1:9200/_cluster/settings'
{% else %}
    - name: 'http://127.0.0.1:9200/_cluster/settings'
{% endif %}
    - method: PUT
    - status: 200
    - request_interval: 5
    - wait_for: 120
    - header_dict:
        Content-Type: "application/json"
    - data_file: /etc/elasticsearch/allocation_settings.json

elasticsearch_no_replicas_template:
  file.managed:
    - name: /etc/elasticsearch/no_replicas_template.json
    - source: salt://{{ slspath }}/files/elastic/no_replicas_template.json
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - require:
      - file: elasticsearch_dirs

elasticsearch_enable_no_replicas_template:
  http.query:
{% if elastic_tls is defined and elastic_tls|int >= 1 %}
    - name: 'https://127.0.0.1:9200/_template/.no_replicas'
{% else %}
    - name: 'http://127.0.0.1:9200/_template/.no_replicas'
{% endif %}
    - method: PUT
    - status: 200
    - header_dict:
        Content-Type: "application/json"
    - data_file: /etc/elasticsearch/no_replicas_template.json

elasticsearch_no_replicas:
  file.managed:
    - name: /etc/elasticsearch/no_replicas.json
    - source: salt://{{ slspath }}/files/elastic/no_replicas.json
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - require:
      - file: elasticsearch_dirs

{% if elastic_indices is defined and elastic_indices|int > 0 %}
elasticsearch_set_no_replicas:
  http.query:
{% if elastic_tls is defined and elastic_tls|int >= 1 %}
    - name: 'https://127.0.0.1:9200/*/_settings'
{% else %}
    - name: 'http://127.0.0.1:9200/*/_settings'
{% endif %}
    - method: PUT
    - status: 200
    - header_dict:
        Content-Type: "application/json"
    - data_file: /etc/elasticsearch/no_replicas.json
{% endif %}
{% if elastic_deprecationLog is defined and elastic_deprecationLog == "null" %}
elasticsearch_set_deprecation_log_no_replicas:
  http.query:
{% if elastic_tls is defined and elastic_tls|int >= 1 %}
    - name: 'https://127.0.0.1:9200/.logs-deprecation.elasticsearch-default/_settings'
{% else %}
    - name: 'http://127.0.0.1:9200/.logs-deprecation.elasticsearch-default/_settings'
{% endif %}
    - method: PUT
    - status: 200
    - header_dict:
        Content-Type: "application/json"
    - data_file: /etc/elasticsearch/no_replicas.json
{% endif %}
{% else %}
elasticsearch_skip_installation:
  cmd.run:
    - name: echo "Skipping Elastic install."
{% endif %}

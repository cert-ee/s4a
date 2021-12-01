{% set elastic_version_installed = salt['pkg.version']('elasticsearch') %}
{% set elastic_nodes = salt['cmd.run'](cmd='curl -s 127.0.0.1:9200/_cluster/health | jq .number_of_nodes', python_shell=True) %}
{% set elastic_status = salt['cmd.run'](cmd='curl -s 127.0.0.1:9200/_cluster/health | jq -r .status', python_shell=True) %}

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
    - version: 7.15.1
    - hold: true
    - update_holds: true
    - refresh: true
    - require:
      - pkgrepo: elastic7x_repo
      - pkg: dependency_pkgs
  service.running:
    - enable: true
    - full_restart: true
    - watch:
      - pkg: elasticsearch
      - file: elasticsearch_yml

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
      - /srv/elasticsearch
      - /var/log/elasticsearch
      - /var/run/elasticsearch
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
    - name: 'http://localhost:9200/_cluster/settings'
    - method: PUT
    - status: 200
    - request_interval: 5
    - wait_for: 120
    - header_dict:
        Content-Type: "application/json"
    - data_file: /etc/elasticsearch/allocation_settings.json

{% if elastic_status == "yellow" %}
elasticsearch_replicas_settings:
  file.managed:
    - name: /etc/elasticsearch/no_replicas.json
    - source: salt://{{ slspath }}/files/elastic/no_replicas.json
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - require:
      - file: elasticsearch_dirs

elasticsearch_disable_replicas:
  http.query:
    - name: 'http://localhost:9200/*/_settings'
    - method: PUT
    - status: 200
    - header_dict:
        Content-Type: "application/json"
    - data_file: /etc/elasticsearch/no_replicas.json
{% endif %}
{% endif %}

elasticsearch_skip_installation:
  cmd.run:
    - name: echo "Skipping Elastic install."

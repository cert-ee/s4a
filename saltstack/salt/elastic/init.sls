# Install elasticsearch 5.5.1
include:
  - elastic.deps

elastic_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch 5.x Repo
    - name: deb https://artifacts.elastic.co/packages/5.x/apt stable main
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - file: /etc/apt/sources.list.d/elasticsearch.list

elastic_pkg:
  pkg.installed:
    - name: elasticsearch
    - version: 5.5.1
    - refresh: True
    - require:
      - pkgrepo: elastic_repo
      - pkg: oracle-java8-installer

# Install elasticsearch 6.8.6
include:
  - elastic.deps

elastic_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch 6.8.x Repo
    - name: deb https://artifacts.elastic.co/packages/6.x/apt stable main
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - file: /etc/apt/sources.list.d/elasticsearch.list

elastic_pkg:
  pkg.installed:
    - name: elasticsearch
    - version: 6.8.6
    - refresh: True
    - require:
      - pkgrepo: elastic_repo
      - pkg: openjdk-8-jre

{% set evebox_es_index_name = "logstash-*" %}

include:
  - detector.elastic

golang_repo:
  pkgrepo.managed:
    - humanname: Golang 1.8 PPA for Ubuntu 16.04 Xenial
    - ppa: longsleep/golang-backports

evebox_repo:
  pkgrepo.managed:
    - humanname: EveBox Debian Repository
    - name: deb [arch=amd64] http://files.evebox.org/evebox/debian stable main
    - key_url: https://evebox.org/files/GPG-KEY-evebox
    - file: /etc/apt/sources.list.d/evebox.list
    - clean_file: true

evebox_pkgs:
  pkg.latest:
    - refresh: true
    - pkgs:
      - git
      - golang-go
      - evebox
      - curl
      - python-elasticsearch
    - require:
      - pkgrepo: golang_repo
      - pkgrepo: evebox_repo
      - pkg: elasticsearch

GeoLite2-City:
  file.managed:
    - name: /etc/evebox/GeoLite2-City.mmdb.gz
    - source: https://repo.s4a.cert.ee/GeoLite2-City.mmdb.gz
    - skip_verify: true
  module.run:
    - name: archive.gunzip
    - gzipfile: /etc/evebox/GeoLite2-City.mmdb.gz
    - onchanges: [ { file: /etc/evebox/GeoLite2-City.mmdb.gz } ]
    - options: -f

evebox_conf:
  file.managed:
    - name: /etc/evebox/evebox.yaml
    - source: salt://{{ slspath }}/files/evebox/evebox.yaml.jinja
    - template: jinja

evebox_set_template:
  elasticsearch_index_template.present:
    - name: "{{ evebox_es_index_name }}"
    - definition:
        template: "{{ evebox_es_index_name }}-*"
        order: 1
        settings:
          number_of_shards: 1
        mappings:
          '_default_':
             '_all':
               enabled: true
               norms: false
             dynamic_templates:
               - message_field:
                   path_match: message
                   match_mapping_type: string
                   mapping:
                     type: text
                     norms: false
               - string_fields:
                  match: "*"
                  match_mapping_type: string
                  mapping:
                    type: text
                    norms: false
                    fields:
                      keyword:
                        type: keyword
                        ignore_above: 256
             properties:
               '@timestamp':
                 type: date
                 include_in_all: false
               '@version':
                 type: keyword
                 include_in_all: false
               geoip:
                 dynamic: true
                 properties:
                   ip:
                     type: ip
                   location:
                     type: geo_point
                   latitude:
                     type: half_float
                   longitude:
                     type: half_float
    - require:
      - pkg: evebox_pkgs

evebox_agent_conf:
  file.managed:
    - name: /etc/evebox/agent.yaml
    - source: salt://{{ slspath }}/files/evebox/agent.yaml.jinja
    - template: jinja

evebox_defaults_conf:
  file.managed:
    - name: /etc/default/evebox
    - source: salt://{{ slspath }}/files/evebox/evebox.defaults.jinja
    - template: jinja

evebox_sysd_service:
  file.managed:
    - name: /lib/systemd/system/evebox.service
    - source: salt://{{ slspath }}/files/evebox/evebox.service
    - template: jinja

evebox_service_enabled:
  service.enabled:
    - names:
       - evebox
       - evebox-agent

evebox_service:
  service.running:
    - names:
       - evebox
       - evebox-agent
    - full_restart: true
    - watch:
      - pkg: evebox_pkgs
      - file: evebox_conf
      - file: evebox_sysd_service
      - service: evebox_service_enabled

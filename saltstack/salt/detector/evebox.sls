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
    - source: https://repo.s4a.cert.ee/geoip/GeoLite2-City.mmdb.gz
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

suricata_template:
  cmd.run:
    - name: curl -s -H "Accept: application/json" -H "Content-Type:application/json" -XPUT "http://localhost:9200/_template/suricata" -d '{"index_patterns" : ["suricata*"],"settings" : {"index" : {"number_of_shards" : "1"}},"mappings" : {"doc" : {"properties" : {"@timestamp" : { "type" : "date"},"dest_ip" : {"type" : "ip"},"src_ip" : {"type" : "ip"},"geoip" : {"dynamic" : true,"properties" : {"ip" : {"type" : "ip"},"location" : {"type" : "geo_point"},"latitude" : {"type" : "half_float"},"longitude" : {"type" : "half_float"}}}}}}}' > /dev/null 2>&1

replace_reporting_index:
  cmd.run:
    - name: sed 's/logstash/suricata*/' -i /usr/share/s4a-detector/app/server/common/models/report.js

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

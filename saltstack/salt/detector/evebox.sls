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
  file.managed:
    - name: /etc/evebox/suricata-template-6.8.json
    - source: salt://{{ slspath }}/files/evebox/suricata-template-6.8.json
    - user: root
    - group: root
    - mode: 750
  file.managed:
    - name: /usr/local/bin/import-suricata-template.sh
    - source: salt://{{ slspath }}/files/evebox/import-suricata-template.sh
    - user: root
    - group: root
    - mode: 755
  cmd.run:
    - name: /usr/local/bin/import-suricata-template.sh 
    - runas: root
    - require:
      -file: import-suricata-template.sh
  file.replace:
    - path: /usr/share/s4a-detector/app/server/common/models/report.js
    - pattern: logstash
    - repl: suricata
  
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

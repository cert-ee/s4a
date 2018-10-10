golang_repo:
  pkgrepo.managed:
    - humanname: Golang 1.8 PPA for Ubuntu 16.04 Xenial
    - ppa: longsleep/golang-backports

evebox_repo:
  pkgrepo.managed:
    - humanname: EveBox Debian Repository
    - name: deb [arch=amd64] http://files.evebox.org/evebox/debian unstable main
    - key_url: https://evebox.org/files/GPG-KEY-evebox
    - file: /etc/apt/sources.list.d/evebox.list

evebox_pkgs:
  pkg.latest:
    - refresh: true
    - pkgs:
      - git
      - golang-go
      - evebox
      - curl
    - require:
      - pkgrepo: golang_repo
      - pkgrepo: evebox_repo

GeoLite2-City:
  file.managed:
    - name: /etc/evebox/GeoLite2-City.mmdb.gz
    - source: http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz
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

evebox_db_template:
  file.managed:
    - name: /etc/evebox/elasticsearch-template-es5x.json
    - source: salt://{{ slspath }}/files/evebox/elasticsearch-template-es5x.json

evebox_set_template:
  cmd.run:
    - name: curl -XPUT -d@/etc/evebox/elasticsearch-template-es5x.json http://{{ salt['pillar.get']('central:es', 'localhost') }}:9200/_template/logstash
    - require:
      - pkg: evebox_pkgs
      - file: evebox_db_template

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
    - watch:
      - pkg: evebox_pkgs
      - file: evebox_conf
      - service: evebox_service_enabled

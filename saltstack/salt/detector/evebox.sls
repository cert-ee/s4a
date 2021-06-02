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
      - evebox
      - curl
      - python3-elasticsearch
    - require:
      - pkgrepo: evebox_repo

GeoLite2-City:
  file.managed:
    - name: /etc/evebox/GeoLite2-City.mmdb.gz
    - source: https://repo.s4a.cert.ee/geoip/GeoLite2-City.mmdb.gz
    - skip_verify: true
  cmd.run:
    - name: gunzip -f /etc/evebox/GeoLite2-City.mmdb.gz
    - require:
      - file: /etc/evebox/GeoLite2-City.mmdb.gz

evebox_conf:
  file.managed:
    - name: /etc/evebox/evebox.yaml
    - source: salt://{{ slspath }}/files/evebox/evebox.yaml.jinja
    - template: jinja

fetch_suricata_template:
  file.managed:
    - name: /etc/evebox/suricata-template-7.x.json
    - source: salt://{{ slspath }}/files/evebox/suricata-template-7.x.json
    - user: root
    - group: root
    - mode: 755

elasticsearch_suricata_template:
  http.query:
    - name: 'http://localhost:9200/_template/suricata'
    - method: PUT
    - status: 200
    - header_dict:
        Content-Type: "application/json"
    - data_file: /etc/evebox/suricata-template-7.x.json

evebox_agent_conf:
  file.managed:
    - name: /etc/evebox/agent.yaml
    - source: salt://{{ slspath }}/files/evebox/agent.yaml

evebox_defaults_conf:
  file.managed:
    - name: /etc/default/evebox
    - source: salt://{{ slspath }}/files/evebox/evebox.defaults.jinja
    - template: jinja

evebox_sysd_service:
  file.managed:
    - name: /lib/systemd/system/evebox.service
    - source: salt://{{ slspath }}/files/evebox/evebox.service

evebox_agent_sysd_service:
  file.managed:
    - name: /lib/systemd/system/evebox-agent.service
    - source: salt://{{ slspath }}/files/evebox/agent.service

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
      - file: evebox_agent_sysd_service
      - service: evebox_service_enabled

evebox-agent_component_enable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "evebox"},{ $set: { installed:true } })'

include:
  - detector.deps
  - detector.geoip

evebox:
  cmd.run:
    - name: apt-mark unhold evebox
  pkg.installed:
    - version: 1:0.17.1
    - hold: true
    - update_holds: true
    - refresh: true
    - require:
      - evebox_repo

evebox_pkgs:
  pkg.latest:
    - refresh: true
    - pkgs:
      - git
      - curl
      - python3-elasticsearch

{% if not salt['file.symlink_exists' ]('/etc/evebox/GeoLite2-City.mmdb') %}
/etc/evebox/GeoLite2-City.mmdb:
  file.symlink:
    - target: /srv/s4a-detector/geoip/GeoLite2-City.mmdb
{% endif %}

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
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "evebox"},{ $set: { installed:true } })'

{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set int_def = salt['pillar.get']('detector:int_default', 'eth1' ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}
{% if connect_test.result == True %}
{% 	set int = salt.http.query('http://'+api.host+':'+api.port|string+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] | tojson %}
{% endif %}
{% if int is not defined or int == "" %}
{% 	set int = int_def %}
{% endif %}
include:
  - detector.deps
  - detector.capture_interface

suricata_group:
  group.present:
    - name: suricata
    - system: true

suricata_user:
  user.present:
    - name: suricata
    - fullname: Sir Icata Dumpalot
    - shell: /bin/false
    - home: /tmp
    - groups:
      - suricata
    - watch:
      - group: suricata_group

detector_suricata_yaml:
  file.managed:
    - name: /etc/suricata/suricata.yaml
    - source: salt://{{ slspath }}/files/suricata/suricata.yaml
    - user: suricata
    - group: suricata
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int }}
    - watch:
      - user: suricata_user
      - pkg: suricata

suricata:
  cmd.run:
    - name: apt-mark unhold suricata
  pkg.latest:
    - refresh: True
    - require:
        - suricata_repo

suricata_package_hold:
  cmd.run:
    - name: apt-mark hold suricata

detector_suricata_default:
  file.managed:
    - name: /etc/default/suricata
    - source: salt://{{ slspath }}/files/suricata/suricata.default.jinja
    - user: suricata
    - group: suricata
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int }}
    - watch:
      - user: suricata_user

detector_suricata_file_logrotate:
  file.managed:
    - name: /etc/logrotate.d/suricata
    - source: salt://{{ slspath }}/files/suricata/suricata.logrotate
    - user: root
    - group: root
    - mode: 644

detector_suricata_reload:
  file.managed:
    - name: /usr/local/bin/reload_suricata_rules.sh
    - source: salt://{{ slspath }}/files/suricata/reload_suricata_rules.sh
    - user: root
    - group: root
    - mode: 755

detector_suricata_rules_perms:
  file.directory:
    - name: /etc/suricata/rules
    - user: s4a
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: suricata

detector_suricata_logs_perms:
  file.directory:
    - name: /var/log/suricata
    - user: suricata
    - group: suricata
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: suricata

suricata_service_dead:
  service.dead:
    - name: suricata

suricata_sevice_enable:
  service.running:
    - name: suricata
    - enable: true

suricata_component_enable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "suricata"},{ $set: { installed:true } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "suricata"},{ $set: { enabled:true } })'

suricata_init_rules_status:
  cmd.run:
    - name: /usr/local/bin/reload_suricata_rules.sh init

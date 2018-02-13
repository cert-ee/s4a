{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': '4000'}) %}
{% set int_def = salt['pillar.get']('detector:int_default', 'eth1' ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}
{% if connect_test.result == True %}
{% 	set int = salt.http.query('http://'+api.host+':'+api.port+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] %}
{% endif %}
{% if int is not defined or int == "" %}
{% 	set int = int_def %}
{% endif %}
include:
  - detector.deps

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
      - pkg: suricata_pkg

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

suricata_pkg:
  pkg.installed:
    - refresh: true
    - pkgs:
        - suricata
        - pfring-dkms
        - pfring-tcpdump
        - pfring-lib
    - require:
        - pkgrepo: s4a_repo
  service.running:
    - name: suricata
    - enable: true
    - reload: true
    - watch:
      - pkg: suricata_pkg
      - file: detector_suricata_yaml

detector_suricata_file_service:
  file.managed:
    - name: /etc/systemd/system/suricata.service
    - source: salt://{{ slspath }}/files/suricata/suricata.service
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - defaults:
        int: {{ int }}

detector_suricata_file_logrotate:
  file.managed:
    - name: /etc/logrotate.d/suricata
    - source: salt://{{ slspath }}/files/suricata/suricata.logrotate
    - user: root
    - group: root
    - mode: 644

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
      - pkg: suricata_pkg

detector_suricata_systemctl_reload:
  module.run:
    - name: service.systemctl_reload
    - watch:
      - file: detector_suricata_file_service

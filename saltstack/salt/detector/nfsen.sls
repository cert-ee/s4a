{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set int_def = salt['pillar.get']('detector:int_default', ['eth1'] ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}
{% if connect_test.result == True %}
{% 	set int = salt.http.query('http://'+api.host+':'+api.port|string+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] %}
{% endif %}
{% if int is not defined or int == "" %}
{% 	set int = int_def %}
{% endif %}

include:
  - detector.deps
  - detector.capture_interface

nfsen_config_yaml:
  file.managed:
    - name: /etc/nfsen.conf
    - source: salt://{{ slspath }}/files/nfsen/nfsen.conf.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch:
      - pkg: nfsen_pkg

nfsen_profile_cleanup_1:
  file.line:
    - name: /usr/local/nfsen/profiles-stat/live/profile.dat
    - match: channel = peer[12].*peer[12]
    - mode: delete

nfsen_profile_cleanup_2:
  file.line:
    - name: /usr/local/nfsen/profiles-stat/live/profile.dat
    - match: channel = peer[12].*peer[12]
    - mode: delete
    - watch:
      - file: nfsen_profile_cleanup_1

nfsen_pkg:
  pkg.installed:
    - refresh: true
    - name: nfsen
    - require:
        - pkgrepo: s4a_repo
  service.running:
    - name: nfsen
    - enable: true
    - full_restart: true
    - watch:
      - pkg: nfsen_pkg
      - file: nfsen_config_yaml
      - file: nfsen_profile_cleanup_2

fprobe_defaults_yaml:
  file.managed:
    - name: /etc/default/fprobe
    - source: salt://{{ slspath }}/files/fprobe/fprobe.defaults.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int[0] }}

fprobe_pkg:
  pkg.installed:
    - refresh: true
    - names:
       - fprobe
       - libpcap0.8

fprobe_init_script:
  file.managed:
    - name: /etc/init.d/fprobe
    - source: salt://{{ slspath }}/files/fprobe/fprobe.init
    - user: root
    - group: root
    - mode: 644

fprobe_service:
  service.running:
    - name: fprobe
    - enable: true
    - watch:
      - pkg: fprobe_pkg
      - file: fprobe_defaults_yaml
      - file: fprobe_init_script

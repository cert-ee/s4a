{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set int_def = salt['pillar.get']('detector:int_default', ['eth1'] ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}

{% if connect_test.result == True %}
{% set int = salt.http.query('http://'+api.host+':'+api.port|string+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] %}
{% set result_moloch = salt.http.query('http://'+api.host+':'+api.port|string+'/api/components/moloch', decode=true ) %}
{% set result_settings = salt.http.query('http://'+api.host+':'+api.port|string+'/api/settings/paths', decode=true ) %}
{% endif %}

{% if int is not defined or int == "" %}
{% set int = int_def %}
{% endif %}

{% if result_moloch is defined and result_moloch['dict'] is defined %}
{% set moloch_config = result_moloch['dict'] | tojson %}
{% endif %}

{% if result_settings is defined and result_settings['dict'] is defined %}
{% set path_moloch_wise_ini = result_settings['dict']['path_moloch_wise_ini'] | tojson %}
{% set path_moloch_yara_ini = result_settings['dict']['path_moloch_yara_ini'] | tojson %}
{% endif %}

{% set es = 'http://' + salt['pillar.get']('detector.elasticsearch.host', 'localhost' ) + ':9200' %}
{% set elastic_status = salt['cmd.run'](cmd='curl -s 127.0.0.1:9200/_cluster/health | jq -r .status', python_shell=True) %}
{% set elastic_nodes = salt['cmd.run'](cmd='curl -s 127.0.0.1:9200/_cluster/health | jq .number_of_nodes', python_shell=True) %}
{% set molochDBVersion = salt['cmd.run'](cmd='curl -s 127.0.0.1:9200/_template/*sessions2_template?filter_path=**._meta.molochDbVersion | jq -r .sessions2_template.mappings._meta.molochDbVersion', python_shell=True) %}

# Note:
# After initial installation user needs to be added
# /data/moloch/bin/moloch_add_user.sh <user id> <user friendly name> <password> [<options>]
#

include:
  - detector.deps
  - detector.elastic
  - detector.capture_interface

# ttyname failed: Inappropriate ioctl for device
neutralize_annoying_message:
  file.line:
    - name: /root/.profile
    - match: ^mesg n || true
    - mode: replace
    - content: tty -s && mesg n || true

detector_moloch_pkg:
  pkg.latest:
    - name: moloch
    - refresh: True
    - require:
      - pkgrepo: s4a_repo_focal
#      - pkg: elasticsearch

# Note:
# Moloch viewer does not use user from configration, but runs under 'daemon'
# instead.
detector_moloch_dir_perms:
  file.directory:
    - names:
      - /data/moloch/raw
      - /srv/pcap
    - user: nobody
    - group: root
    - mode: 755
    - require:
      - pkg: detector_moloch_pkg

detector_moloch_log_perms:
  file.directory:
    - names:
      - /data/moloch/logs
    - user: nobody
    - group: root
    - mode: 755
    - require:
      - pkg: detector_moloch_pkg

detector_moloch_logrotate:
  file.managed:
    - name: /etc/logrotate.d/moloch
    - source: salt://{{ slspath }}/files/moloch/moloch_logrotate
    - user: root
    - group: root
    - mode: 644

{% if elastic_nodes|int == 1 %}
detector_moloch_daily_script:
  file.managed:
    - name: /data/moloch/db/daily.sh
    - source: salt://{{ slspath }}/files/moloch/moloch.cron.daily.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - require:
      - pkg: detector_moloch_pkg
    - defaults:
        es: {{ es }}

detector_moloch_daily_cron:
  cron.present:
    - name: /data/moloch/db/daily.sh
    - user: root
    - minute: 0
    - hour: '*/1'
    - require:
      - file: detector_moloch_daily_script
{% endif %}

detector_moloch_limits_conf:
  file.managed:
    - name: /etc/security/limits.d/99-moloch.conf
    - source: salt://{{ slspath }}/files/moloch/moloch_limits.conf
    - user: root
    - group: root
    - mode: 644

detector_moloch_update_geo_sh:
  file.managed:
    - name: /data/moloch/bin/moloch_update_geo.sh
    - source: salt://{{ slspath }}/files/moloch/moloch_update_geo.sh.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja

detector_moloch_rc_local:
  file.managed:
    - name: /etc/rc.local
    - source: salt://{{ slspath }}/files/moloch/moloch_rc_local
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - defaults:
        int: {{ int | tojson }}

detector_moloch_config_ini:
  file.managed:
    - name: /data/moloch/etc/config.ini
    - source: salt://{{ slspath }}/files/moloch/config.ini
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int | join(';') }}
        es: {{ es }}
        moloch_config: {{ moloch_config }}
{% if path_moloch_yara_ini is defined %}
        path_moloch_yara_ini: {{ path_moloch_yara_ini }}
{% endif %}
    - require:
      - pkg: detector_moloch_pkg

detector_moloch_update_geo:
  cmd.run:
    - name: /data/moloch/bin/moloch_update_geo.sh > /dev/null
    - cwd: /data/moloch/bin
    - runas: root
    - require:
      - pkg: detector_moloch_pkg

detector_moloch_check_elastic_up:
  http.wait_for_successful_query:
    - name: 'http://localhost:9200/_cluster/health'
    - method: GET
    - status: 200
    - request_interval: 5
    - wait_for: 120
    - header_dict:
        Content-Type: "application/json"

{% if molochDBVersion is not defined or molochDBVersion == "-1" or molochDBVersion|int < 64 %}
detector_moloch_db:
  service.dead:
    - names:
       - molochcapture
       - molochviewer
  cmd.run:
    - name: echo INIT | /data/moloch/db/db.pl {{ es }} init
    - runas: root
    - require:
      - pkg: detector_moloch_pkg
      - detector_moloch_check_elastic_up
{% endif %}

{% if molochDBVersion is defined and molochDBVersion|int == 64 and elastic_status == "green" %}
detector_moloch_db_upgrade:
  service.dead:
    - names:
       - molochcapture
       - molochviewer
  cmd.run:
    - name: echo UPGRADE | /data/moloch/db/db.pl {{ es }} upgrade
    - runas: root
    - require:
      - pkg: detector_moloch_pkg
      - detector_moloch_check_elastic_up
{% endif %}

detector_moloch_admin_profile_sh:
  file.managed:
    - name: /usr/local/bin/moloch_reset_profile.sh
    - source: salt://{{ slspath }}/files/moloch/moloch_reset_profile.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - pkg: detector_moloch_pkg

detector_moloch_admin_profile:
  cmd.run:
    - name: /usr/local/bin/moloch_reset_profile.sh admin admin
    - runas: root
    - require:
      - file: detector_moloch_admin_profile_sh

detector_moloch_reset_users_sh:
  file.managed:
    - name: /usr/local/bin/moloch_reset_users.sh
    - source: salt://{{ slspath }}/files/moloch/moloch_reset_users.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - pkg: detector_moloch_pkg

detector_moloch_reset_users:
  cmd.run:
    - name: /usr/local/bin/moloch_reset_users.sh
    - runas: root
    - require:
      - file: detector_moloch_reset_users_sh

detector_moloch_capture_systemd:
  file.managed:
    - name: /etc/systemd/system/molochcapture.service
    - source: salt://{{ slspath }}/files/moloch/molochcapture.service
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int | join(';') }}

detector_moloch_viewer_systemd:
  file.managed:
    - name: /etc/systemd/system/molochviewer.service
    - source: salt://{{ slspath }}/files/moloch/molochviewer.service
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int | join(';') }}

detector_moloch_systemctl_reload:
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: detector_moloch_viewer_systemd
      - file: detector_moloch_capture_systemd

detector_moloch_capture_service:
  service.running:
    - name: molochcapture
    - enable: true
    - full_restart: true
    - init_delay: 5
    - require:
      - file: detector_moloch_capture_systemd
    - watch:
      - pkg: detector_moloch_pkg
      - cmd: detector_moloch_admin_profile
      - file: detector_moloch_config_ini

detector_moloch_capture_component_enable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochcapture"},{ $set: { installed:true } })'

detector_moloch_viewer_service:
  service.running:
    - name: molochviewer
    - enable: true
    - full_restart: true
    - init_delay: 5
    - require:
      - file: detector_moloch_viewer_systemd
    - watch:
      - pkg: detector_moloch_pkg
      - cmd: detector_moloch_admin_profile

detector_moloch_viewer_component_enable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochviewer"},{ $set: { installed:true } })'

detector_moloch_drop_tls:
  file.managed:
    - name: /data/moloch/etc/drop_tls.yaml
    - source: salt://{{ slspath }}/files/moloch/drop_tls.yaml.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja

{% if moloch_config is defined and moloch_config['configuration'] is defined and moloch_config['configuration']['wise_enabled'] is defined and moloch_config['configuration']['wise_enabled'] == True %}
moloch_wise_conf:
  file.managed:
    - name: /data/moloch/etc/wise.ini
    - source: salt://{{ slspath }}/files/moloch/wise.ini.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - defaults:
       moloch_config: {{ moloch_config }}

{% if path_moloch_wise_ini is defined and salt['file.file_exists' ](path_moloch_wise_ini) %}
moloch_wise_conf_sources:
   file.append:
   - name: /data/moloch/etc/wise.ini
   - source: {{ path_moloch_wise_ini }}
   - watch:
     - file: moloch_wise_conf
{% endif %}

detector_moloch_wise_systemd:
  file.managed:
    - name: /etc/systemd/system/molochwise.service
    - source: salt://{{ slspath }}/files/moloch/molochwise.service
    - user: root
    - group: root
    - mode: 644
    - template: jinja

{% if moloch_config is defined and moloch_config['configuration'] is defined and moloch_config['configuration']['wise_enabled'] is defined and moloch_config['configuration']['wise_enabled'] == True %}
detector_moloch_wise_service:
  service.running:
    - name: molochwise
    - enable: true
    - full_restart: true
    - require:
      - file: detector_moloch_wise_systemd
      - file: moloch_wise_conf
    - watch:
      - pkg: detector_moloch_pkg
{% else %}
detector_moloch_wise_service:
  service.dead:
    - name: molochwise
    - enable: false
{% endif %}
{% endif %}

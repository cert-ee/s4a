{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set int_def = salt['pillar.get']('detector:int_default', ['eth1'] ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}

{% if connect_test.result == True %}
{% set int = salt.http.query('http://'+api.host+':'+api.port|string+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] %}
{% set result_moloch = salt.http.query('http://'+api.host+':'+api.port|string+'/api/components/moloch', decode=true ) %}

{% set path_moloch_wise_ini = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/settings/paths | jq -r .path_moloch_wise_ini', python_shell=True) %}
{% set path_moloch_yara_ini = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/settings/paths | jq -r .path_moloch_yara_ini', python_shell=True) %}
{% set wise_enabled = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/components/moloch | jq -r .configuration.wise_enabled', python_shell=True) %}
{% set wise_installed = salt['cmd.run'](cmd='source /etc/default/s4a-detector && mongo --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval \'db.component.find({"_id" : "molochwise"})\'|jq -r .installed', python_shell=True) %}
{% endif %}

{% if int is not defined or int == "" %}
{% set int = int_def %}
{% endif %}

{% if result_moloch is defined and result_moloch['dict'] is defined %}
{% set moloch_config = result_moloch['dict'] | tojson %}
{% endif %}

#{% set es = 'http://' + salt['pillar.get']('detector.elasticsearch.host', 'localhost' ) + ':9200' %}
{% set es = 'http://127.0.0.1:9200' %}
{% set elastic_status = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_cluster/health | jq -r .status', python_shell=True) %}
{% set elastic_node_count = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_cluster/health | jq -r .number_of_nodes', python_shell=True) %}
{% set molochDBVersion = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_template/*sessions2_template?filter_path=**._meta.molochDbVersion | jq -r .sessions2_template.mappings._meta.molochDbVersion', python_shell=True) %}
{% set arkimeDBVersion = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_template/*arkime_sessions3_template?filter_path=**._meta.molochDbVersion | jq -r .arkime_sessions3_template.mappings._meta.molochDbVersion', python_shell=True) %}
{% set arkimeShards = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_template/*arkime_sessions3_template | jq -r .[].settings.index.number_of_shards', python_shell=True) %}
{% set arkimeShardsPerNode = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_template/*arkime_sessions3_template | jq -r .[].settings.index.routing.allocation.total_shards_per_node', python_shell=True) %}
{% set arkimeReplicas = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_template/*arkime_sessions3_template | jq -r .[].settings.index.number_of_replicas', python_shell=True) %}



# Note:
# After initial installation user needs to be added
# /data/moloch/bin/moloch_add_user.sh <user id> <user friendly name> <password> [<options>]
#

include:
  - detector.deps
  - detector.capture_interface

# ttyname failed: Inappropriate ioctl for device
neutralize_annoying_message:
  file.line:
    - name: /root/.profile
    - match: ^mesg n || true
    - mode: replace
    - content: tty -s && mesg n || true

{% if (arkimeDBVersion is defined and arkimeDBVersion|int < 78) and elastic_status == "green" %}
install_moloch_4x:
  pkg.installed:
    - sources:
      - moloch: {{ salt['pillar.get']('detector:repo') }}/pool/universe/m/moloch/moloch_4.3.2-1_amd64.deb

detector_moloch_4x_db_upgrade:
  service.dead:
    - names:
       - molochcapture
       - molochviewer
  cmd.run:
    - name: echo UPGRADE | /data/moloch/db/db.pl {{ es }} upgrade --shardsPerNode {{ arkimeShardsPerNode }}  --shards {{ arkimeShards }} --replicas {{ arkimeReplicas }}
    - runas: root
{% endif %}

{% if (arkimeDBVersion is defined and arkimeDBVersion|int >= 78) and elastic_status == "green" %}
moloch:
  cmd.run:
    - name: apt-mark unhold moloch
  pkg.installed:
    - version: 5.2.0-1
    - hold: true
    - update_holds: true
    - refresh: True
    - require:
      - pkgrepo: s4a_repo
{% endif %}

detector_moloch_dir_perms:
  file.directory:
    - names:
      - /data/moloch/raw
      - /srv/pcap
    - user: nobody
    - group: root
    - mode: 755
    - require:
      - pkg: moloch

detector_moloch_log_perms:
  file.directory:
    - names:
      - /var/log/moloch
    - user: nobody
    - group: root
    - mode: 755
    - require:
      - pkg: moloch

detector_moloch_logrotate:
  file.managed:
    - name: /etc/logrotate.d/moloch
    - source: salt://{{ slspath }}/files/moloch/moloch_logrotate
    - user: root
    - group: root
    - mode: 644

detector_moloch_daily_script:
  file.managed:
    - name: /data/moloch/db/daily.sh
    - source: salt://{{ slspath }}/files/moloch/moloch.cron.daily.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - require:
      - pkg: moloch
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

detector_moloch_geo_cron:
  cron.present:
    - name: /data/moloch/bin/moloch_update_geo.sh > /dev/null 2>&1
    - user: root
    - minute: 5
    - hour: '0'
    - dayweek: '*/3'
    - require:
      - file: detector_moloch_update_geo_sh

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
      - pkg: moloch

detector_moloch_update_geo:
  cmd.run:
    - name: /data/moloch/bin/moloch_update_geo.sh > /dev/null
    - cwd: /data/moloch/bin
    - runas: root
    - require:
      - pkg: moloch

detector_moloch_check_elastic_up:
  http.wait_for_successful_query:
    - name: 'http://localhost:9200/_cluster/health'
    - method: GET
    - status: 200
    - request_interval: 5
    - wait_for: 120
    - header_dict:
        Content-Type: "application/json"

{% if elastic_status == "green" and (molochDBVersion == "null" or molochDBVersion|int < 64) and ( arkimeDBVersion == "null" ) %}
detector_moloch_db:
  service.dead:
    - names:
       - molochcapture
       - molochviewer
  cmd.run:
{% if elastic_node_count|int ==  1 %}
    - name: echo INIT | /data/moloch/db/db.pl {{ es }} init --replicas 0
{% else %}
    - name: echo INIT | /data/moloch/db/db.pl {{ es }} init --shardsPerNode 3 --shards {{ elastic_node_count }} --replicas 1
{% endif %}
    - runas: root
    - require:
      - pkg: moloch
      - detector_moloch_check_elastic_up
{% endif %}

{% if (arkimeDBVersion is defined and arkimeDBVersion|int >= 78 and arkimeDBVersion|int < 80) and elastic_status == "green" %}
detector_moloch_db_upgrade:
  service.dead:
    - names:
       - molochcapture
       - molochviewer
  cmd.run:
    - name: echo UPGRADE | /data/moloch/db/db.pl {{ es }} upgrade --shardsPerNode {{ arkimeShardsPerNode }}  --shards {{ arkimeShards }} --replicas {{ arkimeReplicas }}
    - runas: root
    - require:
      - pkg: moloch
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
      - pkg: moloch

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
      - pkg: moloch

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
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: detector_moloch_viewer_systemd
      - file: detector_moloch_capture_systemd

{% if wise_enabled is defined and path_moloch_wise_ini is defined and wise_enabled == "true" %}
moloch_wise_conf:
  file.managed:
    - name: /data/moloch/etc/wise.ini
    - source: salt://{{ slspath }}/files/moloch/wise.ini
    - user: root
    - group: root
    - mode: 755

{% if salt['file.file_exists'](path_moloch_wise_ini) %}
moloch_wise_conf_sources:
   file.append:
   - name: /data/moloch/etc/wise.ini
   - source: {{ path_moloch_wise_ini }}
   - watch:
     - file: moloch_wise_conf
{% endif %}

{% if not salt['file.file_exists' ]('/srv/s4a-detector/moloch/wise_lan_ips.txt') %}
local_network_tags:
  file.managed:
    - name: /srv/s4a-detector/moloch/wise_lan_ips.txt
    - source: salt://{{ slspath }}/files/moloch/wise_lan_ips.txt
    - user: s4a
    - group: s4a
    - mode: 644
{% endif %}

detector_moloch_wise_systemd:
  file.managed:
    - name: /etc/systemd/system/molochwise.service
    - source: salt://{{ slspath }}/files/moloch/molochwise.service
    - user: root
    - group: root
    - mode: 644

detector_moloch_wise_enable_service:
  cmd.run:
    - name: systemctl enable molochwise.service

detector_moloch_wise_start_service:
  service.running:
    - name: molochwise

detector_moloch_wise_component_enabled:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongo --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { installed:true } })'
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { enabled:true } })'

{% elif wise_enabled is defined and wise_installed is defined and wise_installed == "true" and wise_enabled == "false"%}
detector_moloch_wise_service:
  service.dead:
    - name: molochwise
    - enable: false

detector_moloch_wise_component_disable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongo --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { installed:false } })'
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "moloch"},{ $set: { "configuration.wise_enabled" : false } })'
{% endif %}

detector_moloch_enable_molochcapture:
  cmd.run:
    - name: systemctl enable molochcapture.service

detector_moloch_enable_molochviewer:
  cmd.run:
    - name: systemctl enable molochviewer.service

detector_moloch_capture_service:
  service.running:
    - name: molochcapture
    - enable: True
    - full_restart: True
    - init_delay: 5
    - require:
      - file: detector_moloch_capture_systemd
    - watch:
      - pkg: moloch
      - cmd: detector_moloch_admin_profile
      - file: detector_moloch_config_ini

detector_moloch_viewer_service:
  service.running:
    - name: molochviewer
    - enable: True
    - full_restart: True
    - init_delay: 5
    - require:
      - file: detector_moloch_viewer_systemd
    - watch:
      - pkg: moloch
      - cmd: detector_moloch_admin_profile

detector_moloch_drop_tls:
  file.managed:
    - name: /data/moloch/etc/drop_tls.yaml
    - source: salt://{{ slspath }}/files/moloch/drop_tls.yaml.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja

detector_moloch_component_enable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "moloch"},{ $set: { installed:true } })'
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochviewer"},{ $set: { installed:true } })'
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochcapture"},{ $set: { installed:true } })'
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "moloch"},{ $set: { enabled:true } })'
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochviewer"},{ $set: { enabled:true } })'
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochcapture"},{ $set: { enabled:true } })'

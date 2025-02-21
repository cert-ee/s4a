{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
#{% set int_def = salt['pillar.get']('detector:int_default', ['eth1'] ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}

{% if connect_test.result == True %}
{% set int = salt.http.query('http://'+api.host+':'+api.port|string+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] %}
{% set result_moloch = salt.http.query('http://'+api.host+':'+api.port|string+'/api/components/moloch', decode=true ) %}

{% set path_arkime_wise_ini = salt['cmd.run'](cmd='curl -s http://127.0.0.1:4000/api/settings/paths | jq -r .path_moloch_wise_ini', python_shell=True) %}
{% set path_arkime_yara_ini = salt['cmd.run'](cmd='curl -s http://127.0.0.1:4000/api/settings/paths | jq -r .path_moloch_yara_ini', python_shell=True) %}
{% set wise_enabled = salt['cmd.run'](cmd='curl -s http://127.0.0.1:4000/api/components/moloch | jq -r .configuration.wise_enabled', python_shell=True) %}
{% set wise_installed = salt['cmd.run'](cmd='curl -s http://127.0.0.1:4000/api/components/moloch | jq -r .installed', python_shell=True) %}
{% endif %}

{% if int is not defined or int == "" %}
{% set int = int_def %}
{% endif %}

{% if result_moloch is defined and result_moloch['dict'] is defined %}
{% set arkime_config = result_moloch['dict'] | tojson %}
{% endif %}

#{% set es = 'http://' + salt['pillar.get']('detector.elasticsearch.host', '127.0.0.1' ) + ':9200' %}
{% set es = 'http://127.0.0.1:9200' %}
{% set elastic_status = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_cluster/health | jq -r .status', python_shell=True) %}
{% set elastic_node_count = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_cluster/health | jq -r .number_of_nodes', python_shell=True) %}
{% set arkimeDBVersion = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_template/*arkime_sessions3_template?filter_path=**._meta.molochDbVersion | jq -r .arkime_sessions3_template.mappings._meta.molochDbVersion', python_shell=True) %}
{% set arkimeShards = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_template/*arkime_sessions3_template | jq -r .[].settings.index.number_of_shards', python_shell=True) %}
{% set arkimeShardsPerNode = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_template/*arkime_sessions3_template | jq -r .[].settings.index.routing.allocation.total_shards_per_node', python_shell=True) %}
{% set arkimeReplicas = salt['cmd.run'](cmd='curl -s http://127.0.0.1:9200/_template/*arkime_sessions3_template | jq -r .[].settings.index.number_of_replicas', python_shell=True) %}


{% if salt['file.file_exists' ]('/etc/s4a-detector/wise_lan_ips_dns.ini') %}
{% set wise_reversedns_enabled = salt['cmd.run'](cmd='cat /etc/s4a-detector/wise_lan_ips_dns.ini | sed -r "/^(\ * |)#/d" | xargs | sed "/^$/d" | wc -l', python_shell=True) %}
{% endif %}

include:
  - detector.deps
  - detector.capture_interface

# ttyname failed: Inappropriate ioctl for device
#neutralize_annoying_message:
#  file.line:
#    - name: /root/.profile
#    - match: ^mesg n || true
#    - mode: replace
#    - content: tty -s && mesg n || true

arkime:
  pkg.latest:
#  pkg.installed:
#    - version: 5.6.1-1
    - hold: true
    - update_holds: true
    - refresh: True
    - require:
      - pkgrepo: s4a_repo

detector_arkime_dir_perms:
  file.directory:
    - names:
      - /srv/pcap
    - user: nobody
    - group: root
    - mode: 755
    - require:
      - pkg: arkime

detector_arkime_log_perms:
  file.directory:
    - names:
      - /var/log/arkime
    - user: nobody
    - group: root
    - mode: 755
    - require:
      - pkg: arkime

detector_arkime_logrotate:
  file.managed:
    - name: /etc/logrotate.d/arkime
    - source: salt://{{ slspath }}/files/arkime/arkime_logrotate
    - user: root
    - group: root
    - mode: 644

detector_arkime_daily_script:
  file.managed:
    - name: /opt/arkime/db/daily.sh
    - source: salt://{{ slspath }}/files/arkime/daily.sh.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - require:
      - pkg: arkime
    - defaults:
        es: {{ es }}

detector_arkime_daily_cron:
  cron.present:
    - name: /opt/arkime/db/daily.sh
    - user: root
    - minute: 0
    - hour: '*/1'
    - require:
      - file: detector_arkime_daily_script

detector_arkime_geo_cron:
  cron.present:
    - name: /opt/arkime/bin/arkime_update_geo.sh > /dev/null 2>&1
    - user: root
    - minute: 5
    - hour: '0'
    - dayweek: '*/3'
    - require:
      - file: detector_arkime_update_geo_sh

detector_arkime_limits_conf:
  file.managed:
    - name: /etc/security/limits.d/99-arkime.conf
    - source: salt://{{ slspath }}/files/arkime/arkime_limits.conf
    - user: root
    - group: root
    - mode: 644

detector_arkime_update_geo_sh:
  file.managed:
    - name: /opt/arkime/bin/arkime_update_geo.sh
    - source: salt://{{ slspath }}/files/arkime/arkime_update_geo.sh.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja

detector_arkime_config_ini:
  file.managed:
    - name: /opt/arkime/etc/config.ini
    - source: salt://{{ slspath }}/files/arkime/config.ini.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int | join(';') }}
        es: {{ es }}
        arkime_config: {{ arkime_config }}
{% if path_arkime_yara_ini is defined %}
        path_arkime_yara_ini: {{ path_arkime_yara_ini }}
{% endif %}
    - require:
      - pkg: arkime

detector_arkime_update_geo:
  cmd.run:
    - name: /opt/arkime/bin/arkime_update_geo.sh > /dev/null
    - cwd: /opt/arkime/bin
    - runas: root
    - require:
      - pkg: arkime

detector_arkime_check_elastic_up:
  http.wait_for_successful_query:
    - name: {{ es }}/_cluster/health
    - method: GET
    - status: 200
    - request_interval: 5
    - wait_for: 120
    - header_dict:
        Content-Type: "application/json"

{% if elastic_status == "green" and ( arkimeDBVersion == "null" ) %}
detector_arkime_db:
  service.dead:
    - names:
       - arkimecapture
       - arkimeviewer
  cmd.run:
{% if elastic_node_count|int ==  1 %}
    - name: echo INIT | /opt/arkime/db/db.pl {{ es }} init --replicas 0
{% else %}
    - name: echo INIT | /opt/arkime/db/db.pl {{ es }} init --shardsPerNode 3 --shards {{ elastic_node_count }} --replicas 1
{% endif %}
    - runas: root
    - require:
      - pkg: arkime
      - detector_arkime_check_elastic_up
{% endif %}

{% if (arkimeDBVersion is defined and arkimeDBVersion != "null" and arkimeDBVersion|int < 82) and elastic_status == "green" %}
detector_arkime_db_upgrade:
  service.dead:
    - names:
       - arkimecapture
       - arkimeviewer
  cmd.run:
    - name: echo UPGRADE | /opt/arkime/db/db.pl {{ es }} upgrade --shardsPerNode {{ arkimeShardsPerNode }}  --shards {{ arkimeShards }} --replicas {{ arkimeReplicas }}
    - runas: root
    - require:
      - pkg: arkime
      - detector_arkime_check_elastic_up
{% endif %}

detector_arkime_admin_profile_sh:
  file.managed:
    - name: /usr/local/bin/arkime_reset_profile.sh
    - source: salt://{{ slspath }}/files/arkime/arkime_reset_profile.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - pkg: arkime

detector_arkime_admin_profile:
  cmd.run:
    - name: /usr/local/bin/arkime_reset_profile.sh admin admin
    - runas: root
    - require:
      - file: detector_arkime_admin_profile_sh

detector_arkime_reset_users_sh:
  file.managed:
    - name: /usr/local/bin/arkime_reset_users.sh
    - source: salt://{{ slspath }}/files/arkime/arkime_reset_users.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - pkg: arkime

detector_arkime_reset_users:
  cmd.run:
    - name: /usr/local/bin/arkime_reset_users.sh
    - runas: root
    - require:
      - file: detector_arkime_reset_users_sh

detector_arkime_capture_systemd:
  file.managed:
    - name: /etc/systemd/system/arkimecapture.service
    - source: salt://{{ slspath }}/files/arkime/arkimecapture.service
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int | join(';') }}

detector_arkime_viewer_systemd:
  file.managed:
    - name: /etc/systemd/system/arkimeviewer.service
    - source: salt://{{ slspath }}/files/arkime/arkimeviewer.service
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int | join(';') }}

detector_arkime_systemctl_reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: detector_arkime_viewer_systemd
      - file: detector_arkime_capture_systemd

{% if wise_enabled is defined and path_arkime_wise_ini is defined and wise_enabled == "true" %}
arkime_wise_conf:
  file.managed:
    - name: /opt/arkime/etc/wise.ini
    - source: salt://{{ slspath }}/files/arkime/wise.ini
    - user: root
    - group: root
    - mode: 755

{% if salt['file.file_exists'](path_arkime_wise_ini) %}
arkime_wise_conf_sources:
   file.append:
   - name: /opt/arkime/etc/wise.ini
   - source: {{ path_arkime_wise_ini }}
   - watch:
     - file: arkime_wise_conf
{% endif %}

{% if not salt['file.file_exists' ]('/etc/s4a-detector/wise_lan_ips.ini') %}
local_network_tags:
  file.managed:
    - name: /etc/s4a-detector/wise_lan_ips.ini
    - source: salt://{{ slspath }}/files/arkime/wise_lan_ips.ini
    - user: s4a
    - group: s4a
    - mode: 644
{% endif %}

{% if wise_reversedns_enabled is defined and wise_reversedns_enabled == "1" %}
arkime_wise_reversedns_conf_sources:
   file.append:
   - name: /opt/arkime/etc/wise.ini
   - source: /etc/s4a-detector/wise_lan_ips_dns.ini
{% endif %}

{% if not salt['file.file_exists' ]('/etc/s4a-detector/wise_lan_ips_dns.ini') %}
local_network_reverse_dns:
  file.managed:
    - name: /etc/s4a-detector/wise_lan_ips_dns.ini
    - source: salt://{{ slspath }}/files/arkime/wise_lan_ips_dns.ini
    - user: s4a
    - group: s4a
    - mode: 644
{% endif %}

detector_arkime_wise_systemd:
  file.managed:
    - name: /etc/systemd/system/arkimewise.service
    - source: salt://{{ slspath }}/files/arkime/arkimewise.service
    - user: root
    - group: root
    - mode: 644

detector_arkime_wise_enable_service:
  cmd.run:
    - name: systemctl enable arkimewise.service


detector_arkime_wise_component_enabled:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongosh --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { installed:true } })'
        mongosh --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { enabled:true } })'

detector_arkime_wise_service:
  service.running:
    - name: arkimewise
    - enable: True
    - full_restart: True
    - init_delay: 5
    - require:
      - file: detector_arkime_wise_systemd
    - watch:
      - pkg: arkime
      - file: arkime_wise_conf

{% elif wise_enabled is defined and wise_installed is defined and wise_installed == "true" and wise_enabled == "false"%}
detector_arkime_wise_service:
  service.dead:
    - name: arkimewise
    - enable: false

detector_arkime_wise_component_disable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongosh --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { installed:false } })'
        mongosh --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { enabled:false } })'
{% endif %}

detector_arkime_enable_arkimecapture:
  cmd.run:
    - name: systemctl enable arkimecapture.service

detector_arkime_enable_arkimeviewer:
  cmd.run:
    - name: systemctl enable arkimeviewer.service

detector_arkime_capture_service:
  service.running:
    - name: arkimecapture
    - enable: True
    - full_restart: True
    - init_delay: 5
    - require:
      - file: detector_arkime_capture_systemd
    - watch:
      - pkg: arkime
      - cmd: detector_arkime_admin_profile
      - file: detector_arkime_config_ini

detector_arkime_viewer_service:
  service.running:
    - name: arkimeviewer
    - enable: True
    - full_restart: True
    - init_delay: 5
    - require:
      - file: detector_arkime_viewer_systemd
    - watch:
      - pkg: arkime
      - cmd: detector_arkime_admin_profile

detector_arkime_drop_tls:
  file.managed:
    - name: /opt/arkime/etc/drop_tls.yaml
    - source: salt://{{ slspath }}/files/arkime/drop_tls.yaml.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja

detector_arkime_component_enable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "moloch"},{ $set: { installed:true } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochviewer"},{ $set: { installed:true } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochcapture"},{ $set: { installed:true } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "moloch"},{ $set: { enabled:true } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochviewer"},{ $set: { enabled:true } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochcapture"},{ $set: { enabled:true } })'

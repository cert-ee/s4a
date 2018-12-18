{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set int_def = salt['pillar.get']('detector:int_default', ['eth1'] ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}
{% if connect_test.result == True %}
{% 	set int = salt.http.query('http://'+api.host+':'+api.port|string+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] %}
{% 	set result_moloch = salt.http.query('http://'+api.host+':'+api.port|string+'/api/components/moloch', decode=true ) %}
{% 	set result_settings = salt.http.query('http://'+api.host+':'+api.port|string+'/api/settings/paths', decode=true ) %}
{% endif %}
{% if int is not defined or int == "" %}
{% 	set int = int_def %}
{% endif %}
{% if result_moloch is defined and result_moloch['dict'] is defined %}
{% 	set moloch_config = result_moloch['dict'] %}
{% endif %}
{% if result_settings is defined and result_settings['dict'] is defined %}
{%	set path_moloch_wise_ini = result_settings['dict']['path_moloch_wise_ini'] %}
{%	set path_moloch_yara_ini = result_settings['dict']['path_moloch_yara_ini'] %}
{% endif %}

{% set es = 'http://' + salt['pillar.get']('detector.elasticsearch.host', 'localhost' ) + ':9200' %}

# Note:
# After initial installation user needs to be added
# /data/moloch/bin/moloch_add_user.sh <user id> <user friendly name> <password> [<options>]
#

include:
  - detector.deps

# ttyname failed: Inappropriate ioctl for device
neutralize_annoying_message:
  file.line:
    - name: /root/.profile
    - match: ^mesg n || true
    - mode: replace
    - content: tty -s && mesg n || true

detector_moloch_pkg:
  pkg.installed:
    - name: moloch
    - refresh: True
    - require:
      - pkgrepo: s4a_repo

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
    - special: '@daily'
    - require:
      - file: detector_moloch_daily_script

detector_moloch_limits_conf:
  file.managed:
    - name: /etc/security/limits.d/99-moloch.conf
    - source: salt://{{ slspath }}/files/moloch/moloch_limits.conf
    - user: root
    - group: root
    - mode: 644

detector_moloch_rc_local:
  file.managed:
    - name: /etc/rc.local
    - source: salt://{{ slspath }}/files/moloch/moloch_rc_local
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - defaults:
        int: {{ int | join(';') }}

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

{% set moloch_db_status = "-1" %}
{% if salt['file.file_exists' ]('/data/moloch/db/db.pl') %}
{% set moloch_db_status = salt['cmd.run'](cmd='/data/moloch/db/db.pl ' + es + ' info | grep "DB Version" | awk \{\'print $3\'}', python_shell=True) %}
{% endif %}
{% if not moloch_db_status or moloch_db_status == "-1" %}
detector_moloch_db:
  cmd.run:
    - name: echo INIT | /data/moloch/db/db.pl {{ es }} init
    - runas: root
    - require:
      - pkg: detector_moloch_pkg
    - require_in:
      - detector_moloch_admin_profile
    - watch_in:
      - detector_moloch_capture_service
      - detector_moloch_viewer_service
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
    - require:
      - file: detector_moloch_capture_systemd
    - watch:
      - pkg: detector_moloch_pkg
      - cmd: detector_moloch_admin_profile

detector_moloch_viewer_service:
  service.running:
    - name: molochviewer
    - enable: true
    - full_restart: true
    - require:
      - file: detector_moloch_viewer_systemd
    - watch:
      - pkg: detector_moloch_pkg
      - cmd: detector_moloch_admin_profile

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

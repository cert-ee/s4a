{% set path_arkime_wise_ini = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/settings/paths | jq -r .path_moloch_wise_ini', python_shell=True) %}
{% set wise_enabled = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/components/moloch | jq -r .configuration.wise_enabled', python_shell=True) %}
{% set wise_installed = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/components/moloch | jq -r .configuration.wise_installed', python_shell=True) %}

{% if salt['file.file_exists' ]('/etc/s4a-detector/wise_lan_ips_dns.ini') %}
{% set wise_reversedns_enabled = salt['cmd.run'](cmd='cat /etc/s4a-detector/wise_lan_ips_dns.ini | sed -r "/^(\ * |)#/d" | xargs | sed "/^$/d" | wc -l', python_shell=True) %}
{% endif %}

{% if wise_enabled is defined and wise_installed is defined and path_arkime_wise_ini is defined and wise_installed == "true" and wise_enabled == "true" %}
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
{% endif %}

{% if wise_reversedns_enabled is defined and wise_reversedns_enabled == "1" %}
arkime_wise_reversedns_conf_sources:
   file.append:
   - name: /opt/arkime/etc/wise.ini
   - source: /etc/s4a-detector/wise_lan_ips_dns.ini
{% endif %}

arkimewise_stop:
  service.dead:
    - name: arkimewise

arkimewise_start:
  service.running:
    - name: arkimewise
{% endif %}

{% set path_moloch_wise_ini = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/settings/paths | jq -r .path_moloch_wise_ini', python_shell=True) %}
{% set wise_enabled = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/components/moloch | jq -r .configuration.wise_enabled', python_shell=True) %}
{% set wise_installed = salt['cmd.run'](cmd='source /etc/default/s4a-detector && mongo --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval \'db.component.find({"_id" : "molochwise"})\'|jq -r .installed', python_shell=True) %}

{% if salt['file.file_exists' ]('/etc/s4a-detector/wise_lan_ips_dns.ini') %}
{% set wise_reversedns_enabled = salt['cmd.run'](cmd='cat /etc/s4a-detector/wise_lan_ips_dns.ini | sed -r "/^(\ * |)#/d" | xargs | sed "/^$/d" | wc -l, python_shell=True) %}
{% endif %}

{% if wise_enabled is defined and wise_installed is defined and path_moloch_wise_ini is defined and wise_installed == "true" and wise_enabled == "true" %}
moloch_wise_conf:
  file.managed:
    - name: /data/moloch/etc/wise.ini
    - source: salt://{{ slspath }}/files/moloch/wise.ini
    - user: root
    - group: root
    - mode: 755

moloch_wise_conf_sources:
   file.append:
   - name: /data/moloch/etc/wise.ini
   - source: {{ path_moloch_wise_ini }}

{% if wise_reversedns_enabled == "1" %}
moloch_wise_reversedns_conf_sources:
   file.append:
   - name: /data/moloch/etc/wise.ini
   - source: salt://{{ slspath }}/files/moloch/wise_lan_ips_dns.ini
{% endif %}

molochwise_stop:
  service.dead:
    - name: molochwise

molochwise_start:
  service.running:
    - name: molochwise
{% endif %}

{% set path_moloch_wise_ini = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/settings/paths | jq -r .path_moloch_wise_ini', python_shell=True) %}
{% set wise_enabled = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/components/moloch | jq -r .configuration.wise_enabled', python_shell=True) %}
{% set wise_installed = salt['cmd.run'](cmd='source /etc/default/s4a-detector && mongo --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval \'db.component.find({"_id" : "molochwise"})\'|jq -r .installed', python_shell=True) %}

{% if wise_enabled is defined and wise_installed is defined and path_moloch_wise_ini is defined and wise_installed == "true" and wise_enabled == "true"%}
{% if salt['file.file_exists'](path_moloch_wise_ini) %}
moloch_wise_conf_sources:
   file.append:
   - name: /data/moloch/etc/wise.ini
   - source: {{ path_moloch_wise_ini }}
{% endif %}

molochwise_stop:
  service.dead:
    - name: molochwise

molochwise_start:
  service.running:
    - name: molochwise
{% endif %}

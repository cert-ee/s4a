{% set path_moloch_wise_ini = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/settings/paths | jq -r .path_moloch_wise_ini', python_shell=True) %}
{% set wise_enabled = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/components/moloch | jq -r .configuration.wise_enabled', python_shell=True) %}
{% set wise_installed = salt['cmd.run'](cmd='source /etc/default/s4a-detector && mongo --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval \'db.component.find({"_id" : "molochwise"})\'|jq -r .installed', python_shell=True) %}

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

{% if wise_installed == "false" and wise_enabled == "true"%}
detector_moloch_wise_systemd:
  file.managed:
    - name: /etc/systemd/system/molochwise.service
    - source: salt://{{ slspath }}/files/moloch/molochwise.service
    - user: root
    - group: root
    - mode: 644

detector_moloch_wise_service:
  service.running:
    - name: molochwise
    - enable: true
    - full_restart: true
    - init_delay: 5
    - require:
      - file: detector_moloch_wise_systemd
      - file: moloch_wise_conf
    - watch:
      - file: moloch_wise_conf_sources

detector_moloch_wise_component_enabled:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongo --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { installed:true } })'
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { enabled:true } })'
{% elif wise_enabled is defined and wise_installed is defined and wise_installed == "true" and wise_enabled == "true"%}
molochwise_stop:
  service.dead:
    - name: molochwise

molochwise_start:
  service.running:
    - name: molochwise
{% endif %}

{% else %}
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

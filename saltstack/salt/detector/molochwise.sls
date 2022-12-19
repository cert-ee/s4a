{% set wise_enabled = salt['cmd.run'](cmd='curl -s http://localhost:4000/api/components/moloch | jq -r .configuration.wise_enabled', python_shell=True) %}
{% set wise_installed = salt['cmd.run'](cmd='source /etc/default/s4a-detector && mongo --quiet $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval \'db.component.find({"_id" : "molochwise"})\'|jq -r .installed', python_shell=True) %}

{% if wise_enabled is defined and wise_installed is defined and wise_installed == "true" and wise_enabled == "true"%}
molochwise_stop:
  service.dead:
    - name: molochwise

molochwise_start:
  service.running:
    - name: molochwise
{% endif %}

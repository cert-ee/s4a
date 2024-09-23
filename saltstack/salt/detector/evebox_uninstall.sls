evebox_service:
  service.dead:
    - names:
       - evebox
       - evebox-agent
    - enable: false

evebox_pkg:
  pkg.purged:
    - name: evebox
  watch:
    - service: evebox_service

evebox-agent_component_disable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "evebox"},{ $set: { installed:false } })'

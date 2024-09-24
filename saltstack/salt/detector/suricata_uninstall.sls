suricata_unhold:
  pkg.unheld:
    - pkgs:
      - suricata

suricata_pkg:
  service.dead:
    - name: suricata
    - enable: false
  pkg.purged:
    - names:
      - suricata

suricata_component_disable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "suricata"},{ $set: { installed:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "suricata"},{ $set: { enabled:false } })'

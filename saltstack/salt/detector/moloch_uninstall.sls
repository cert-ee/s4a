detector_moloch_pkg:
  service.dead:
    - names:
       - molochcapture
       - molochviewer
    - enable: false
  pkg.purged:
    - name: moloch

detector_moloch_capture_component_disable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochcapture"},{ $set: { installed:false } })'

detector_moloch_viewer_component_disable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochviewer"},{ $set: { installed:false } })'

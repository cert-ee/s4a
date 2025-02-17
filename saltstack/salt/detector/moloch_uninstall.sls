detector_moloch_pkg:
  cmd.run:
    - name: apt-mark unhold moloch
  service.dead:
    - names:
       - molochcapture
       - molochviewer
       - molochwise
    - enable: false
  pkg.purged:
    - name: moloch

detector_moloch_remove_files:
  file.absent:
    - names: 
      - /etc/logrotate.d/moloch
      - /etc/systemd/system/molochcapture.service
      - /etc/systemd/system/molochviewer.service
      - /data/moloch/db/daily.sh

detector_moloch_remove_daily_cron:
  cron.absent:
    - name: /data/moloch/db/daily.sh
    - user: root
    - minute: 0
    - hour: '*/1'

detector_moloch_remove_geo_cron:
  cron.present:
    - name: /data/moloch/bin/moloch_update_geo.sh > /dev/null 2>&1
    - user: root
    - minute: 5
    - hour: '0'
    - dayweek: '*/3'

detector_disable_moloch_components:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "moloch"},{ $set: { installed:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochcapture"},{ $set: { installed:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochviewer"},{ $set: { installed:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { installed:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "moloch"},{ $set: { enabled:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochcapture"},{ $set: { enabled:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochviewer"},{ $set: { enabled:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "molochwise"},{ $set: { enabled:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "moloch"},{ $set: { "configuration.wise_enabled" : false } })'
  require:
    - pkg.purged: moloch

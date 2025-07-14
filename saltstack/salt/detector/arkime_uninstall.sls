detector_arkime_pkg:
  cmd.run:
    - name: apt-mark unhold arkime
  service.dead:
    - names:
       - arkimecapture
       - arkimeviewer
       - arkimewise
    - enable: false
  pkg.purged:
    - name: arkime

detector_arkime_remove_files:
  file.absent:
    - names: 
      - /etc/logrotate.d/arkime
      - /etc/systemd/system/arkimecapture.service
      - /etc/systemd/system/arkimeviewer.service
      - /opt/arkime/db/daily.sh

detector_arkime_remove_daily_cron:
  cron.absent:
    - name: /opt/arkime/db/daily.sh
    - user: root
    - minute: 0
    - hour: '*/1'

detector_arkime_remove_geo_cron:
  cron.absent:
    - name: /opt/arkime/bin/arkime_update_geo.sh > /dev/null 2>&1
    - user: root
    - minute: 5
    - hour: '0'
    - dayweek: '*/3'

detector_disable_arkime_components:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "arkime"},{ $set: { installed:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "arkimecapture"},{ $set: { installed:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "arkimeviewer"},{ $set: { installed:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "arkimewise"},{ $set: { installed:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "arkime"},{ $set: { enabled:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "arkimecapture"},{ $set: { enabled:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "arkimeviewer"},{ $set: { enabled:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "arkimewise"},{ $set: { enabled:false } })'
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.updateOne({"_id": "arkime"},{ $set: { "configuration.wise_enabled" : false } })'
  require:
    - pkg.purged: arkime

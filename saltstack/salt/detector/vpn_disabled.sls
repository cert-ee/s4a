openvpn_service:
  service.dead:
    - name: openvpn
    - enable: false

vpn_component_enable:
  cmd.run:
    - name: |
        source /etc/default/s4a-detector
        mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.component.update({"_id": "vpn"},{ $set: { status:true } })'

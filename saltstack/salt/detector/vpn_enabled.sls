openvpn_service:
  service.running:
    - name: openvpn
    - enable: true

openvpn_service:
  service.running:
    - name: openvpn@detector
    - enable: true

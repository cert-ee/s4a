openvpn_service:
  service.running:
    - name: openvpn
    - enable: true

openvpn@detector_service:
  service.running:
    - name: openvpn@detector
    - enable: true

include:
  - detector.user_uninstall

openvpn_pkg:
  service.dead:
    - name: openvpn@detector
    - enable: false
  pkg.purged:
    - name: openvpn

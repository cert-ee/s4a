include:
  - detector.user_uninstall
  - detector.vpn_disabled

openvpn_pkg:
  service.dead:
    - name: openvpn
    - enable: false
  pkg.purged:
    - name: openvpn

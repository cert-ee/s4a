include:
  - detector.user_uninstall

openvpn_pkg:
  service.dead:
    - name: openvpn
    - enable: false
  pkg.purged:
    - name: openvpn

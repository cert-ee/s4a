openvpn:
  pkg.installed:
    - refresh: True
  service.running:
    - enable: True
    - watch:
      - pkg: openvpn

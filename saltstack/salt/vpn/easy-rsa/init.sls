include:
  - vpn.install

easyrsa_pkg:
  pkg.installed:
    - name: easy-rsa
    - refresh: True

extend:
  openvpn:
    service:
      - enable: False

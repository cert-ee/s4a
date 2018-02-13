# Copy the crl.pem to the openvpn server
# Remember to run the revoke-full script with the client name before executing this state

openvpn_crl_pem:
  file.managed:
    - name: /etc/openvpn/keys/crl.pem
    - source: salt://vpn/files/openvpn-ca/keys/crl.pem
    - user: root
    - group: root
    - mode: 644

openvpn@tcp-443:
  service.running:
    - enable: true
    - watch:
      - file: openvpn_crl_pem


# Copy the crl.pem to the openvpn server
# Remember to run the revoke-full script with the client name before executing this state
# NB! This still needs work
{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}

openvpn_crl_pem:
  file.managed:
    - name: {{ ovpn.keys_path }}/crl.pem
    - source: salt://vpn/files/{{ ovpn.key_ou }}/crl.pem
    - user: root
    - group: root
    - mode: 644

openvpn@tcp-443:
  service.running:
    - enable: True
    - watch:
      - file: openvpn_crl_pem

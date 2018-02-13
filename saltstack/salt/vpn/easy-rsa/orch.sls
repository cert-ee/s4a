{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}
{% set minion = salt['pillar.get']('openvpn:host') %}

easy-rsa_config:
  salt.state:
    - tgt: {{ minion }}
    - sls: vpn.easy-rsa.config

easy-rsa_send_certs:
  salt.state:
    - tgt: {{ minion }}
    - sls: vpn.easy-rsa.send_certs
    - require:
      - salt: easy-rsa_config

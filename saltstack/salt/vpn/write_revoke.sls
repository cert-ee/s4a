{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set openvpn = salt['pillar.get']('openvpn') %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}
{% set data = salt.pillar.get('event_data') %}

openvpn_crl_pem:
  salt.function:
    - name: file.write
    - tgt: {{ salt['pillar.get']('openvpn:host') }}
    - arg:
      - /etc/openvpn/crl.pem
      - {{ data.crl_pem|yaml_dquote }}

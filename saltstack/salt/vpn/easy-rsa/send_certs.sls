{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}

{% set ca_crt_path = 'file://' ~ ovpn.keys_path ~ '/ca.crt' %}
{% set server_crt_path = 'file://' ~ ovpn.keys_path ~ '/' ~ ovpn.key_ou ~ '.crt' %}
{% set server_key_path = 'file://' ~ ovpn.keys_path ~ '/' ~ ovpn.key_ou ~ '.key' %}
{% set crl_path = 'file://' ~ ovpn.keys_path ~ '/crl.pem' %}
{% set ta_path = 'file://' ~ ovpn.keys_path ~ '/ta.key' %}

{% set ca_crt = salt['cp.get_file_str'](path=ca_crt_path) %}
{% set server_crt = salt['cp.get_file_str'](path=server_crt_path) %}
{% set server_key = salt['cp.get_file_str'](path=server_key_path) %}
{% set ta_key = salt['cp.get_file_str'](path=ta_path) %}
{% if salt['file.file_exists'](crl_path) == True %}
{% set crl = salt['cp.get_file_str'](path=crl_path) %}
{% endif %}

vpn/s4a/serial:
  event.send:
    - data:
        'key_ou': {{ ovpn.key_ou }}
        'ca.crt': {{ ca_crt|yaml_dquote }}
        {{ ovpn.key_ou }}.crt: {{ server_crt|yaml_dquote }}
        {{ ovpn.key_ou }}.key: {{ server_key|yaml_dquote }}
        'ta.key': {{ ta_key|yaml_dquote }}
        {% if crl is defined %}
        'crl.pem': {{ crl|yaml_dquote }}
        {% endif %}

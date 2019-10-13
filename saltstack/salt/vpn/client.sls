{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}
{% set data = salt['pillar.get']('data') %}
{% set client = salt['file.basename'](data.path).split('.')[0] %}

openvpn_gen_{{ client }}_conf:
  file.managed:
    - name: {{ ovpn.keys_path}}/{{ client }}.conf
    - source: salt://vpn/files/client.ovpn.jinja
    - template: jinja
    - defaults:
        data: {{ data | tojson }}

{% set data = salt.pillar.get('event_data') %}
{% set key_ou = data.key_ou %}

dir_{{ key_ou }}:
  salt.function:
    - name: file.mkdir
    - tgt: {{ salt['pillar.get']('openvpn:saltmaster') }}
    - arg:
      - /srv/salt/vpn/files/{{ key_ou }}

{%- for key, value in data.items() %}
file_{{ key }}:
  salt.function:
    - name: file.write
    - tgt: {{ salt['pillar.get']('openvpn:saltmaster') }}
    - arg:
      - /srv/salt/vpn/files/{{ key_ou }}/{{ key }}
      - {{ value|yaml_dquote }}
{%- endfor %}

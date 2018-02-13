{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}

include:
  - vpn.easy-rsa

{% if not salt['file.directory_exists'](ovpn.easyrsa_path) %}
create_ca_dir:
  cmd.run:
    - name: make-cadir {{ ovpn.easyrsa_path }}
    - require:
      - pkg: easyrsa_pkg
    - require_in:
      - file: vars
{% endif %}

vars:
  file.managed:
    - name: {{ ovpn.easyrsa_path }}/vars
    - source: salt://vpn/easy-rsa/files/vars.jinja
    - user: root
    - group: root
    - mode: 750
    - template: jinja

keydir:
  file.directory:
    - name: {{ ovpn.keys_path }}
    - makedirs: True
    - user: s4a
    - group: root
    - dir_mode: 755
    - file_mode: 640

index_file:
  file.touch:
    - names:
      - {{ ovpn.keys_path }}/index.txt
    - require:
      - file: keydir

{% set serial_path = ovpn.keys_path ~ '/serial' %}
{% if not salt['file.file_exists'](serial_path) %}
openvpn_key_serial:
  file.managed:
    - name: {{ serial_path }}
    - contents:
      - '01'
    - require:
      - file: keydir
    - require_in:
      - cmd: create_server_keypair
{% endif %}

{% set ca_path = ovpn.keys_path ~ '/ca.crt' %}
{% if not salt['file.file_exists'](ca_path) and ovpn.makeca %}
create_server_keypair:
  cmd.run:
    - names:
       - . {{ ovpn.easyrsa_path }}/vars; export KEY_CN="{{ ovpn.key_ou }}"; {{ ovpn.easyrsa_path }}/pkitool --initca
       - . {{ ovpn.easyrsa_path }}/vars; {{ ovpn.easyrsa_path }}/pkitool --server {{ ovpn.key_ou }}
    - require:
      - file: index_file
      - file: vars
{% endif %}

{% set ta_key_path = ovpn.keys_path ~ '/ta.key' %}
{% if not salt['file.file_exists'](ta_key_path) %}
openvpn_ta_key:
  cmd.run:
    - name: openvpn --genkey --secret ta.key
    - runas: root
    - cwd: {{ ovpn.keys_path }}
    - require:
      - file: keydir
      - pkg: openvpn
{% endif %}

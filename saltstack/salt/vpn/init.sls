{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}

include:
  - vpn.install

openvpn_keys:
  file.directory:
    - name: {{ ovpn.keys_path }}
    - dir_mode: 750
    - file_mode: 640
    - require:
      - pkg: openvpn

openvpn_server_files:
  file.recurse:
    - name: {{ ovpn.keys_path }}
    - source: salt://vpn/files/{{ ovpn.key_ou }}
    - user: root
    - group: root
    - dir_mode: 750
    - file_mode: 640
    - makedirs: True
    - maxdepth: 0

openvpn_crl:
  file.managed:
    - name: /etc/openvpn/crl.pem
    - source: salt://vpn/files/{{ ovpn.key_ou }}/crl.pem
    - user: root
    - group: root
    - mode: 644

{% set dh_file = ovpn.keys_path ~ '/dh' ~ ovpn.key_size ~ '.pem' %}
{% if not salt['file.file_exists'](dh_file) %}
openvpn_dh:
  cmd.run:
    - name: openssl dhparam -out dh{{ ovpn.key_size}}.pem {{ ovpn.key_size }}
    - runas: root
    - cwd: {{ ovpn.keys_path }}
    - require:
      - file: openvpn_keys
{% endif %}

openvpn_server_conf:
  file.managed:
    - name: /etc/openvpn/tcp-443.conf
    - source: salt://vpn/files/server.conf
    - user: root
    - group: root
    - mode: 640
    - template: jinja
    - require:
      - pkg: openvpn
    - watch_in:
      - service: openvpn@tcp-443

vpn_allow_ip_forward:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1

{% if salt['pillar.get']('openvpn:server:ccd_exclusive') == true %}
ccd_configs:
  file.recurse:
    - name: {{ salt['pillar.get']('openvpn:server:ccd_dir', '/etc/openvpn/ccd') }}
    - source: salt://vpn/files/{{ ovpn.key_ou }}/client
    - user: root
    - group: root
    - dir_mode: 750
    - file_mode: 640
    - makedirs: True
    - clean: True
    - watch_in:
      - service: openvpn@tcp-443
{% endif %}

openvpn@tcp-443:
  service.running:
    - enable: True

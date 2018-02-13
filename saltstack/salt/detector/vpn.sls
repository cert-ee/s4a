include:
  - detector.user

easy-rsa:
  pkg.installed: []

openvpn:
  pkg.installed:
    - refresh: true

client_vars:
  file.managed:
    - name: /etc/openvpn/vars
    - source: salt://{{ slspath }}/files/vpn/vars.jinja
    - template: jinja
    - require:
      - pkg: openvpn
    - defaults:
        org: {{ salt['pillar.get']('detector:vpn:org') }}
        email: {{ salt['pillar.get']('detector:vpn:email') }}

client_gen_csr:
  cmd.run:
    - name: source /etc/openvpn/vars && /usr/share/easy-rsa/pkitool --csr --batch detector
    - cwd: /etc/openvpn
    - runas: root
    - creates: /etc/openvpn/detector.csr
    - require:
      - file: client_vars
      - pkg: easy-rsa
      - pkg: openvpn

openvpn_conf_file:
  file.managed:
    - name: /etc/openvpn/detector.conf
    - user: s4a
    - group: root
    - mode: 750
    - replace: false

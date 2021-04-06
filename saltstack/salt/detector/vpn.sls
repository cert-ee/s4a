include:
  - detector.user

openvpn:
  pkg.installed:
    - refresh: true

openvpn_service_disabled:
  service.disabled:
    - name: openvpn

{% if not salt['file.file_exists' ]('/etc/openvpn/detector.conf') %}
python3-m2crypto:
  pkg.installed:
    - refresh: true

ovpn_client_key:
  x509.private_key_managed:
    - name: /etc/openvpn/detector.key
    - bits: 2048

ovpn_client_csr:
  x509.csr_managed:
    - name: /etc/openvpn/detector.csr
    - private_key: /etc/openvpn/detector.key
    - CN: detector
    - C: EE
    - keyUsage: "critical keyEncipherment"
    - require:
        - x509: ovpn_client_key

openvpn_conf_file:
  file.managed:
    - name: /etc/openvpn/detector.conf
    - user: s4a
    - group: root
    - mode: 750
    - replace: false
{% endif %}

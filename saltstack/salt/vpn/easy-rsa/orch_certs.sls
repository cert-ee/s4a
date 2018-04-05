{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}
{% set data = salt.pillar.get('event_data') %}
{% set client = salt['file.basename'](data.path).split('.')[0] %}

{% if salt['file.basename'](data.path).split('.')[1] == 'csr' %}
gen_client_cert:
  salt.function:
    - name: cmd.run
    - tgt: {{ data.id }}
    - arg:
      - . {{ ovpn.easyrsa_path }}/vars; export KEY_CN="{{ client }}"; export KEY_ALTNAMES="DNS:{{ client }}"; $OPENSSL ca -batch -days $KEY_EXPIRE -out "{{ data.path.split('.')[0] }}.crt" -in "{{ data.path }}" $CA_EXT -config "$KEY_CONFIG" -subj '/C={{ ovpn.key_country }}/ST={{ ovpn.key_province }}/L={{ ovpn.key_city }}/CN={{ client }}/name={{ salt['pillar.get']('openvpn:key:key_ou') }}/emailAddress={{ salt['pillar.get']('openvpn:key:key_email') }}'
      - creates: {{ ovpn.keys_path }}/{{ client }}.crt
      - cwd: {{ ovpn.keys_path }}

client_ovpn:
  salt.state:
    - tgt: {{ data.id }}
    - sls: vpn.client
    - pillar:
        data: {{ data }}
    - require:
      - salt: gen_client_cert
{% endif %}

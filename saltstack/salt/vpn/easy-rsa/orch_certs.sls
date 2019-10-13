{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}
{% set data = salt.pillar.get('event_data') %}
{% set client = salt['file.basename'](data.path).split('.')[0] %}

{% if salt['file.basename'](data.path).split('.')[1] == 'csr' and data.change == 'IN_CREATE' %}
gen_client_cert:
  salt.function:
    - name: cmd.run
    - tgt: {{ data.id }}
    - arg:
      - . {{ ovpn.easyrsa_path }}/vars; export KEY_CN="{{ client }}"; export KEY_ALTNAMES="DNS:{{ client }}"; $OPENSSL ca -batch -days $KEY_EXPIRE -out "{{ data.path.split('.')[0] }}.crt" -in "{{ data.path }}" $CA_EXT -config "$KEY_CONFIG" -subj '/C={{ ovpn.key_country }}/ST={{ ovpn.key_province }}/L={{ ovpn.key_city }}/CN={{ client }}/name={{ salt['pillar.get']('openvpn:key:key_ou', 's4a') }}/emailAddress={{ salt['pillar.get']('openvpn:key:key_email', 'noreply@cert.ee') }}' >> /tmp/openssl.log 2>&1

client_ovpn:
  salt.state:
    - tgt: {{ data.id }}
    - sls: vpn.client
    - pillar:
        data: {{ data | tojson }}
    - require:
      - salt: gen_client_cert

{% elif salt['file.basename'](data.path).split('.')[1] == 'csr' and data.change == 'IN_DELETE' %}

expire_client_cert:
  salt.function:
    - name: cmd.run
    - tgt: {{ data.id }}
    - arg:
      - . {{ ovpn.easyrsa_path }}/vars; $OPENSSL ca -config "$KEY_CONFIG" -revoke "{{ data.path.split('.')[0] }}.crt" >> /tmp/openssl.log 2>&1;

cleanup_client_data:
  salt.function:
    - name: cmd.run
    - tgt: {{ data.id }}
    - arg:
       - rm "{{ data.path.split('.')[0] }}.crt" "{{ data.path.split('.')[0] }}.conf"

build_crl:
  salt.function:
    - name: cmd.run
    - tgt: {{ data.id }}
    - arg:
      - cat {{ ovpn.keys_path }}/ca.crt {{ ovpn.keys_path }}/revoke.crt > {{ ovpn.keys_path }}/crl.pem;

file_send_revoke:
  salt.state:
    - tgt: {{ data.id }}
    - sls: vpn.send_revoke
    - require:
      - salt: build_crl

{% endif %}

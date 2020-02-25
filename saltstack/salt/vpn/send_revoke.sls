{% import_yaml "vpn/easy-rsa/defaults.yaml" as defaults %}
{% set ovpn = salt['pillar.get']('openvpn:key', defaults.openvpn, merge=True) %}

{% set crl_pem =  salt['cp.get_file_str'](path=ovpn.keys_path+'/crl.pem') %}

vpn/s4a/revoke:
  event.send:
    - data:
        'crl_pem': {{ crl_pem|yaml_dquote }}


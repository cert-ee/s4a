{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set int_def = salt['pillar.get']('detector:int_default', ['eth1'] ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}
ifupdown:
  pkg.latest:
    - refresh: true
{% if connect_test.result == True %}
{% 	set int = salt.http.query('http://'+api.host+':'+api.port|string+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] %}
{% endif %}
{% if int is not defined or int == "" %}
{% 	set int = int_def %}
{% endif %}
{% for val in int %}

capture_interface_{{ val }}:
  network.managed:
    - name: {{ val }}
    - filename: {{ val }}
    - enabled: True
    - type: eth
    - proto: manual
    - rx: off
    - tx: off
    - sg: off
    - tso: off
    - ufo: off
    - gso: off
    - gro: off
    - lro: off
    - required_in: detector_moloch_capture_service
  cmd.run:
    - name: ifconfig {{ val }} up
{% endfor %}

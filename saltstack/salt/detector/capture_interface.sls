{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set int_def = salt['pillar.get']('detector:int_default', ['eth1'] ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}
{% set current_capture_interfaces_cmd = salt['cmd.run'](cmd='grep -l S4a.Traffic.capture.interface /etc/netplan/*.yaml || true', python_shell=True) %}
{% set current_capture_interfaces = current_capture_interfaces_cmd.splitlines() %}

{% if connect_test.result == True %}
{%	set interfaces = salt.http.query('http://'+api.host+':'+api.port|string+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] %}
{% endif %}

{% if interfaces is defined and interfaces != "" %}

{% for current_int in current_capture_interfaces %}
remove_{{ current_int }}:
  file.absent:
   - names:
     -  {{ current_int }}
{% endfor %}

{% for int in interfaces %}
capture_interface_{{ int }}:
  file.managed:
    - name: /etc/netplan/0{{ loop.index }}-capture-{{ int }}.yaml
    - source: salt://{{ slspath }}/files/netplan/capture_interface.yaml.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        int: {{ int }}
{% endfor %}

netplan_apply:
  cmd.run:
    - name: netplan apply
    - runas: root
{% endif %}

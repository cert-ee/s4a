{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}
{% if connect_test.result == True %}
{%      set detector_status = salt.http.query('http://'+api.host+':'+api.port|string+'/api/registration', decode=true)['dict'] %}
{% endif %}
{% if detector_status is not defined
        or detector_status == ""
        or detector_status[0] is not defined
        or detector_status[0].registration_status != "Approved" %}

abort_because_not_registered:
  cmd.run:
    - name: /bin/false
    - failhard: True

{% else %}
{%      set detector_name = detector_status[0].unique_name %}

include:
  - detector.deps

detector_telegraf_pkg:
  pkg.installed:
    - name: telegraf
    - refresh: true

detector_telegraf_service:
  service.running:
    - name: telegraf
    - watch:
      - pkg: detector_telegraf_pkg
      - file: detector_telegraf_conf
    - enable: true
    - reload: true

detector_telegraf_conf:
  file.recurse:
    - name: /etc/telegraf/
    - source: salt://{{ slspath }}/files/telegraf
    - user: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja
    - require:
      - pkg: detector_telegraf_pkg
    - defaults:
       detector_name: {{ detector_name }}

{% endif %}

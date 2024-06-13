detector_nginx_pkg:
  pkg.installed:
    - refresh: true
    - pkgs:
        - nginx
        - ssl-cert

detector_nginx_conf:
  file.recurse:
    - name: /etc/nginx
    - source: salt://{{ slspath }}/files/nginx
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - require:
      - pkg: detector_nginx_pkg

detector_nginx_site_conf:
  file.managed:
    - name: /etc/nginx/sites-available/default
    - source: salt://{{ slspath }}/files/nginx/sites-available/default.jinja
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja
    - require:
      - pkg: detector_nginx_pkg
      - file: detector_nginx_conf

{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}
{% if connect_test.result == True %}
{% 	set http_result = salt.http.query('http://'+api.host+':'+api.port|string+'/api/components/nginx', decode=true ) %}
{% endif %}
{% if http_result is defined and http_result['dict'] is defined %}
{% 	set certs_config = http_result['dict'] %}
{% endif %}
{% if certs_config is defined and certs_config['configuration'] is defined and certs_config['configuration']['ssl_cert'] is defined and certs_config['configuration']['ssl_key'] is defined and certs_config['configuration']['ssl_chain'] is defined %}
detector_nginx_certs:
  file.managed:
    - name: /etc/nginx/detector.chained.crt
    - source: salt://{{ slspath }}/files/nginx/detector.chained.crt.jinja
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 633
    - template: jinja
    - require:
      - pkg: detector_nginx_pkg
      - file: detector_nginx_conf
      - file: detector_nginx_key

detector_nginx_key:
  file.managed:
    - name: /etc/nginx/detector.key
    - source: salt://{{ slspath }}/files/nginx/detector.key.jinja
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 600
    - template: jinja
    - require:
      - pkg: detector_nginx_pkg
      - file: detector_nginx_conf

{% else %}

detector_nginx_certs:
  cmd.run:
    - name: make-ssl-cert generate-default-snakeoil
    - runas: root
    - creates: /etc/ssl/certs/ssl-cert-snakeoil.pem
    - require:
      - pkg: detector_nginx_pkg
      - file: detector_nginx_conf

{% endif %}

# Just remove some templates, not needed
detector_nginx_site_conf_tmp:
  file.absent:
   - names:
     -  /etc/nginx/sites-available/default.jinja
     -  /etc/nginx/detector.chained.crt.jinja
     -  /etc/nginx/detector.key.jinja


detector_nginx_service:
  service.running:
    - names:
       - nginx
    - enable: true
    - watch:
      - pkg: detector_nginx_pkg
      - file: detector_nginx_conf
      - file: detector_nginx_site_conf
{% if certs_config is defined and certs_config['configuration'] is defined and certs_config['configuration']['ssl_cert'] is defined and certs_config['configuration']['ssl_key'] is defined and certs_config['configuration']['ssl_chain'] is defined %}
      - file: detector_nginx_certs
{% else %}
      - cmd: detector_nginx_certs
{% endif %}

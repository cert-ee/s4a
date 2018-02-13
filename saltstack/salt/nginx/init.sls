include:
  - nginx.conf
  - nginx.pkg

nginx_site:
  file.managed:
    - name: /etc/nginx/sites-available/default
    - source: salt://nginx/files/default.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: nginx_pkg
    - watch_in:
      - service: nginx_service

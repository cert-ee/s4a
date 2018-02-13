include:
  - nginx.pkg
  - nginx.conf
  - nginx.letsencrypt

extend:
  nginx_service:
    service:
      - watch:
        - file: docs_nginx_conf
        - cmd: nginx_letsencrypt_get

docs_nginx_conf:
  file.recurse:
    - name: /etc/nginx
    - source: salt://{{ slspath }}/files/nginx
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja
    - require:
      - pkg: nginx_pkg
      - cmd: nginx_letsencrypt_get

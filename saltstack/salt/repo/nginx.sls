include:
  - nginx.init

extend:
  nginx_service:
    service:
      - watch:
        - file: nginx_conf

  nginx_conf:
    file:
      - source: salt://{{ slspath }}/files/nginx.conf
      - template: jinja

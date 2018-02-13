include:
  - nginx.pkg

nginx_conf:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://nginx/files/nginx.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: nginx_service

nginx_webroot:
  file.directory:
    - names:
      - /srv/{{ grains['fqdn'] }}/www
      - /srv/{{ grains['fqdn'] }}/logs
    - user: www-data
    - group: www-data
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True

nginx_logfiles:
  file.managed:
    - names:
      - /srv/{{ grains['fqdn'] }}/logs/access.log
      - /srv/{{ grains['fqdn'] }}/logs/error.log
    - user: www-data
    - group: adm
    - mode: 640

nginx_ssldir:
  file.directory:
    - name: /etc/nginx/ssl
    - user: root
    - group: root
    - mode: 700

nginx_dhparams:
  cmd.run:
    - name: openssl dhparam -out /etc/nginx/ssl/dhparams.pem 2048
    - env:
      - RANDFILE: /etc/nginx/ssl/.rnd
    - creates: /etc/nginx/ssl/dhparams.pem
    - require:
      - file: nginx_ssldir

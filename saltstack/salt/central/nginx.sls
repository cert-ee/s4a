include:
  - nginx.pkg
  - nginx.letsencrypt

extend:
  nginx_service:
    service:
      - watch:
        - file: central_nginx_conf
        - cmd: nginx_letsencrypt_get
        - file: central_nginx_site_conf

central_php_fpm_pkg:
  pkg.installed:
    - refresh: true
    - pkgs:
        - nginx
        - php-fpm

central_nginx_conf:
  file.recurse:
    - name: /etc/nginx
    - source: salt://{{ slspath }}/files/nginx
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - require:
      - pkg: nginx_pkg

central_nginx_passwd:
  file.managed:
    - name: /etc/nginx/.htpasswd
    - user: s4a
    - group: www-data
    - mode: 640
    - require:
      - file: central_nginx_conf

central_nginx_site_conf:
  file.managed:
    - name: /etc/nginx/sites-available/default
    - source: salt://{{ slspath }}/files/nginx/sites-available/default.jinja
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja
    - require:
      - pkg: nginx_pkg
      - file: central_nginx_conf

# Just remove some templates, not needed
central_nginx_site_conf_tmp:
  file.absent:
    - names:
      - /etc/nginx/sites-available/default.jinja
    - require:
      - file: central_nginx_site_conf

{% for user, hash in salt['pillar.get']('central:htpasswd', {}).items() %}
central_nginx_passwd:
  file.append:
    - name: /etc/nginx/.htpasswd
    - template: jinja
    - text: |
        {{ user }}:{{ hash }}
    - require:
      - pkg: nginx_pkg
{% endfor %}

central_php_fpm_service:
  service.running:
    - name: php7.0-fpm
    - enable: true
    - watch:
      - pkg: central_php_fpm_pkg

nginx_letsencrypt:
  pkgrepo.managed:
    - ppa: certbot/certbot
  pkg.latest:
    - refresh: true
    - pkgs:
      - python-certbot-nginx
    - require:
      - pkgrepo: central_letsencrypt

nginx_set_server_name:
  file.replace:
    - name: /etc/nginx/sites-available/default
    - pattern: server_name _;
    - repl: server_name {{ grains['fqdn'] }} {{ grains['host'] }}.{{ grains['domain'].split('.')[1:]|join('.') }};
    - require:
      - pkg: nginx_letsencrypt

nginx_letsencrypt_get:
  cmd.run:
    - name: certbot --nginx certonly -d {{ grains['fqdn'] }},{{ grains['host'] }}.{{ grains['domain'].split('.')[1:]|join('.') }} --agree-tos -m {{ salt['pillar.get']('le:email') }} -n
    - creates: /etc/letsencrypt/live/{{ grains['fqdn'] }}/fullchain.pem
    - require:
      - pkg: letsencrypt
      - file: nginx_set_server_name

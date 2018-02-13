central_nginx_svc:
  service.dead:
    - names: 
       - php7.0-fpm
       - nginx

central_nginx_pkg:
  pkg.purged:
    - names:
       - php7.0-fpm
       - nginx-common
       - nginx-core


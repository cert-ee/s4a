detector_nginx_svc:
  service.dead:
    - names: 
       - php7.0-fpm
       - nginx

detector_nginx_pkg:
  pkg.purged:
    - names:
       - php7.0-fpm
       - nginx-common
       - nginx-core

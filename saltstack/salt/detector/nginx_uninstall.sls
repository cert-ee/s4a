detector_nginx_svc:
  service.dead:
    - names: 
       - nginx

detector_nginx_pkg:
  pkg.purged:
    - names:
       - nginx-common
       - nginx-core

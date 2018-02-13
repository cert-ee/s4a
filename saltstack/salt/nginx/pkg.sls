nginx_pkg:
  pkg.installed:
    - name: nginx
    - refresh: True

nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - watch:
      - pkg: nginx_pkg

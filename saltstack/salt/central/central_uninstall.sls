s4a-central_svc:
  service.dead:
    - name: s4a-central
    - enable: false

s4a-central_pkg:
  pkg.purged:
    - name: s4a-central

mongodb-org_svc:
  service.dead:
    - name: mongod
    - enable: false

mongodb-org_pkg:
  pkg.purged:
    - pkgs:
        - mongodb-org

nodejs_pkg:
  pkg.purged:
    - pkgs:
        - nodejs
        - yarn

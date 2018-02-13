s4a-detector_svc:
  service.dead:
    - name: s4a-detector
    - enable: false

s4a-detector_pkg:
  pkg.purged:
    - name: s4a-detector

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

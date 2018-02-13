
include:
  - central.deps

mongodb-org:
  pkg.installed:
    - refresh: true
    - pkgs:
        - mongodb-org
    - require:
        - pkgrepo: mongodb-org_repo
  service.running:
    - name: mongod
    - reload: true
    - enable: true
    - watch:
      - pkg: mongodb-org

nodejs:
  pkg.installed:
    - refresh: true
    - pkgs:
        - nodejs
        - yarn

s4a-central:
  pkg.installed:
    - refresh: true
  service.running:
    - name: s4a-central
    - enable: true
    - watch:
      - pkg: s4a-central


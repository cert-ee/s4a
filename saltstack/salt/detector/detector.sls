include:
  - detector.deps
  - detector.cron
  - detector.timesync

mongodb-org:
  pkg.installed:
    - refresh: true
    - pkgs:
        - mongodb-org: latest
        - mongodb-org-database: latest
        - mongodb-mongosh: latest
        - mongodb-org-mongos: latest
        - mongodb-org-server: latest
        - mongodb-org-shell: latest
        - mongodb-org-tools: latest
    - require:
        - pkgrepo: mongodb-org_repo

mongod_conf:
  file.managed:
    - name: /etc/mongod.conf
    - source: salt://{{ slspath }}/files/mongodb/mongod.conf
    - user: root
    - group: root
    - mode: 644

mongod_service:
  service.running:
    - name: mongod
    - full_restart: True
    - enable: true
    - require:
      - mongod_conf
      - mongodb-org
    - watch:
      - pkg: mongodb-org

mongodb_logrotate:
  file.managed:
    - name: /etc/logrotate.d/mongodb
    - source: salt://{{ slspath }}/files/detector/mongodb_logrotate
    - user: root
    - group: root
    - mode: 644

nodejs:
  pkg.latest:
    - refresh: true
    - pkgs:
        - nodejs
        - yarn

s4a-detector:
  pkg.latest:
    - refresh: true
  service.running:
    - name: s4a-detector
    - enable: true
    - watch:
      - pkg: s4a-detector

sudo:
  pkg.installed:
    - refresh: true

detector_sudoers_s4a:
  file.managed:
    - user: root
    - group: root
    - mode: 440
    - name: /etc/sudoers.d/s4a
    - source: salt://{{ slspath }}/files/sudoers/s4a
    - check_cmd: /usr/sbin/visudo -c -f
    - require:
      - pkg: sudo

detector_defaults_s4a:
  file.replace:
    - name: /etc/default/s4a-detector
    - pattern: '^CENTRAL_API_URL\=.+$'
    - repl: CENTRAL_API_URL={{ salt['pillar.get']('detector:central:proto') }}://{{ salt['pillar.get']('detector:central:host') }}:{{ salt['pillar.get']('detector:central:port') }}/api
    - require:
      - pkg: s4a-detector
    - watch_in:
      - service: s4a-detector

detector_gpg_conf:
  file.managed:
    - user: root
    - group: root
    - mode: 440
    - makedirs: true
    - name: /root/.gnupg/gpg.conf
    - source: salt://{{ slspath }}/files/gnupg/gpg.conf

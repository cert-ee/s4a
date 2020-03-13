
elastic5x_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch 5.x Repo
    - name: deb https://artifacts.elastic.co/packages/5.x/apt stable main
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - file: /etc/apt/sources.list.d/elastic-5.x.list

elastic6x_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch 6.x Repo
    - name: deb https://artifacts.elastic.co/packages/6.x/apt stable main
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - file: /etc/apt/sources.list.d/elastic-6.x.list

# Assume that if no version is available, mongo repo is unconfigured and we are in process of installing new detector
{% set mongodb_version_installed = salt['pkg.version']('mongodb-org') %}
{% set mongodb_upgrade_available = salt['pkg.upgrade_available']('mongodb-org') %}
{% if mongodb_version_installed is defined %}
{% 	set mongodb_version = mongodb_version_installed.split('.') %}
{% 	set mongodb_version_major = mongodb_version[0] %}
{% 	set mongodb_version_minor = mongodb_version[1] %}
{% 	set mongodb_version_patch = mongodb_version[2] %}
{% endif %}

{% if mongodb_version_major is defined and mongodb_version_major|int == 3 and mongodb_version_minor|int == 4 and mongodb_upgrade_available == True %}
mongodb-org_repo:
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse
    - key_url: https://www.mongodb.org/static/pgp/server-3.4.asc
    - file: /etc/apt/sources.list.d/mongodb-org-3.4.list
{% elif mongodb_version_major is defined and (mongodb_version_major|int == 3 and mongodb_version_minor|int == 4) or (mongodb_version_major|int == 3 and mongodb_version_minor|int == 6 and mongodb_upgrade_available == True) %}
mongodb-org_repo:
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse
    - key_url: https://www.mongodb.org/static/pgp/server-3.6.asc
    - file: /etc/apt/sources.list.d/mongodb-org-3.6.list
{% elif mongodb_version_major is not defined or not mongodb_version_major or (mongodb_version_major|int == 3 and mongodb_version_minor|int == 6) or mongodb_version_major|int == 4 %}

{% if mongodb_version_major is defined and mongodb_version_major|int == 3 %}
# We have mongo installed, doesn't hurt to upgrade
mongodb-org-upgrade-preps:
  cmd.run:
    - name: |
        source /root/.mongodb.passwd
        mongo -u $MONGODB_USER -p $MONGODB_PASS --authenticationDatabase=admin --eval "db.adminCommand( { setFeatureCompatibilityVersion: \"3.6\" } )"
{% endif %}

mongodb-org_repo:
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse
    - key_url: https://www.mongodb.org/static/pgp/server-4.0.asc
    - file: /etc/apt/sources.list.d/mongodb-org-4.0.list
{% endif %}

nodejs_repo:
  pkgrepo.managed:
    - humanname: nodejs
    - name: deb https://deb.nodesource.com/node_10.x xenial main
    - key_url: https://deb.nodesource.com/gpgkey/nodesource.gpg.key
    - file: /etc/apt/sources.list.d/nodesource.list

influxdata_repo:
  pkgrepo.managed:
    - humanname: influxdata
    - name: deb https://repos.influxdata.com/ubuntu xenial stable
    - keyserver: ha.pool.sks-keyservers.net
    - key_url: https://repos.influxdata.com/influxdb.key
    - file: /etc/apt/sources.list.d/influxdata.list

yarn_repo:
  pkgrepo.managed:
    - humanname: yarn
    - name: deb https://dl.yarnpkg.com/debian/ stable main
    - key_url: https://dl.yarnpkg.com/debian/pubkey.gpg
    - file: /etc/apt/sources.list.d/yarn.list

s4a_repo:
  pkgrepo.managed:
    - humanname: repo-s4a
    - name: deb [trusted=yes arch=amd64] {{ salt['pillar.get']('detector:repo') }} xenial universe
    - key_url: {{ salt['pillar.get']('detector:repo') }}/GPG.pub
    - file: /etc/apt/sources.list.d/repo-s4a.list
    - clean_file: True

# Install Elasticsearch dependencies
dependency_pkgs:
  pkg.installed:
    - refresh: true
    - pkgs:
      - apt-transport-https
      - python-software-properties
      - python-elasticsearch
      - openjdk-8-jre

esnode_limits:
  file.append:
    - name: /etc/security/limits.conf
    - text:
      - elasticsearch - nofile 65535
      - elasticsearch - memlock unlimited
      - root - memlock unlimited

vm.swappiness:
  sysctl.present:
    - value: 0

vm.max_map_count:
  sysctl.present:
    - value: 262144


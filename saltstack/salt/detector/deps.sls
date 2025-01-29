# Assume that if no version is available, mongo repo is unconfigured and we are in process of installing new detector
{% set mongodb_version_installed = salt['pkg.version']('mongodb-org-server') %}
{% set mongodb_upgrade_available = salt['pkg.upgrade_available']('mongodb-org-server') %}
{% if mongodb_version_installed is defined %}
{%	set mongodb_version = mongodb_version_installed.split('.') %}
{%	set mongodb_version_major = mongodb_version[0] %}
{%	set mongodb_version_minor = mongodb_version[1] %}
{%	set mongodb_version_patch = mongodb_version[2] %}
{% endif %}

{% if (mongodb_version_major is defined and mongodb_version_major|int == 5 and mongodb_upgrade_available == True) %}
mongodb-org_repo:
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse
    - key_url: https://www.mongodb.org/static/pgp/server-5.0.asc
    - file: /etc/apt/sources.list.d/mongodb-org-5.0.list
{% elif mongodb_version_major is defined and ((mongodb_version_major|int == 6 and mongodb_upgrade_available == True) or  mongodb_version_major|int == 5) %}
mongodb-org_repo:
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse
    - key_url: https://www.mongodb.org/static/pgp/server-6.0.asc
    - file: /etc/apt/sources.list.d/mongodb-org-6.0.list
{% elif (mongodb_version_major is defined and mongodb_version_major|int >= 6) or mongodb_version_installed == False %}
mongodb-org_repo:
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse
    - key_url: https://www.mongodb.org/static/pgp/server-7.0.asc
    - file: /etc/apt/sources.list.d/mongodb-org-7.0.list
{% endif %}

{% if mongodb_version_major is defined and mongodb_version_major|int == 6 %}
mongodb-org-upgrade-preps:
  cmd.run:
    - name: |
        source /root/.mongodb.passwd
        mongosh -u $MONGODB_USER -p $MONGODB_PASS --authenticationDatabase=admin --eval "db.adminCommand( { setFeatureCompatibilityVersion: \"6.0\" } )"
{% elif mongodb_version_major is defined and mongodb_version_major|int == 5 %}
mongodb-org-upgrade-preps:
  cmd.run:
    - name: |
        source /root/.mongodb.passwd
        mongosh -u $MONGODB_USER -p $MONGODB_PASS --authenticationDatabase=admin --eval "db.adminCommand( { setFeatureCompatibilityVersion: \"5.0\" } )"
{% endif %}

nodejs_repo:
  pkgrepo.managed:
    - humanname: nodejs
    - name: deb https://deb.nodesource.com/node_10.x focal main
    - key_url: https://deb.nodesource.com/gpgkey/nodesource.gpg.key
    - file: /etc/apt/sources.list.d/nodesource.list

influxdata_repo:
  pkgrepo.managed:
    - humanname: influxdata
    - name: deb https://repos.influxdata.com/ubuntu focal stable
    - keyserver: ha.pool.sks-keyservers.net
    - key_url: https://repos.influxdata.com/influxdata-archive_compat.key
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
    - name: deb [trusted=yes arch=amd64] {{ salt['pillar.get']('detector:repo') }} focal universe
    - key_url: {{ salt['pillar.get']('detector:repo') }}/GPG.pub
    - file: /etc/apt/sources.list.d/repo-s4a.list
    - clean_file: True

elastic7x_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch 7.x Repo
    - name: deb [arch=amd64] https://artifacts.elastic.co/packages/7.x/apt stable main
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - file: /etc/apt/sources.list.d/elastic-7.x.list

elastic8x_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch 8.x Repo
    - name: deb [arch=amd64] https://artifacts.elastic.co/packages/8.x/apt stable main
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - file: /etc/apt/sources.list.d/elastic-8.x.list

dependency_pkgs:
  pkg.installed:
    - refresh: true
    - pkgs:
      - apt-transport-https
      - software-properties-common

vm.swappiness:
  sysctl.present:
    - value: 0

vm.max_map_count:
  sysctl.present:
    - value: 262144

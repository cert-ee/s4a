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
  cmd.run:
    - name: curl -fsSL https://www.mongodb.org/static/pgp/server-5.0.asc | gpg --dearmor > /etc/apt/keyrings/mongodb-5.gpg
  file.managed:
    - name: /etc/apt/keyrings/mongodb-5.gpg
    - user: root
    - group: root
    - mode: 755
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [signed-by=/etc/apt/keyrings/mongodb-5.gpg arch=amd64] http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse
    - file: /etc/apt/sources.list.d/mongodb-org-5.0.list
    - clean_file: True
{% elif mongodb_version_major is defined and ((mongodb_version_major|int == 6 and mongodb_upgrade_available == True) or  mongodb_version_major|int == 5) %}
mongodb-org_repo:
  cmd.run:
    - name: curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor > /etc/apt/keyrings/mongodb-6.gpg
  file.managed:
    - name: /etc/apt/keyrings/mongodb-6.gpg
    - user: root
    - group: root
    - mode: 755
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [signed-by=/etc/apt/keyrings/mongodb-6.gpg arch=amd64] http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse
    - file: /etc/apt/sources.list.d/mongodb-org-6.0.list
    - clean_file: True
{% elif (mongodb_version_major is defined and mongodb_version_major|int >= 6) or not mongodb_version_installed %}
mongodb-org_repo:
  cmd.run:
    - name: curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor > /etc/apt/keyrings/mongodb-7.gpg
  file.managed:
    - name: /etc/apt/keyrings/mongodb-7.gpg
    - user: root
    - group: root
    - mode: 755
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [signed-by=/etc/apt/keyrings/mongodb-7.gpg arch=amd64] http://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse
    - file: /etc/apt/sources.list.d/mongodb-org-7.0.list
    - clean_file: True

mongodb-org-remove-old-repos:
  file.absent:
    - names: 
      - /etc/apt/sources.list.d/mongodb-org-5.0.list
      - /etc/apt/sources.list.d/mongodb-org-6.0.list
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

influxdata_repo:
  cmd.run:
    - name: curl -fsSL https://repos.influxdata.com/influxdata-archive_compat.key | gpg --dearmor > /etc/apt/keyrings/influxdata.gpg
  file.managed:
    - name: /etc/apt/keyrings/influxdata.gpg
    - user: root
    - group: root
    - mode: 755
  pkgrepo.managed:
    - humanname: influxdata
    - name: deb [signed-by=/etc/apt/keyrings/influxdata.gpg arch=amd64] https://repos.influxdata.com/ubuntu jammy stable
    - file: /etc/apt/sources.list.d/influxdata.list
    - clean_file: True

yarn_repo:
  cmd.run:
    - name: curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor > /etc/apt/keyrings/yarn.gpg
  file.managed:
    - name: /etc/apt/keyrings/yarn.gpg
    - user: root
    - group: root
    - mode: 755
  pkgrepo.managed:
    - humanname: yarn
    - name: deb [signed-by=/etc/apt/keyrings/yarn.gpg arch=amd64] https://dl.yarnpkg.com/debian/ stable main
    - file: /etc/apt/sources.list.d/yarn.list
    - clean_file: True

s4a_repo:
  cmd.run:
    - name: curl -fsSL {{ salt['pillar.get']('detector:repo') }}/GPG.pub | gpg --dearmor > /etc/apt/keyrings/s4a.gpg
  file.managed:
    - name: /etc/apt/keyrings/s4a.gpg
    - user: root
    - group: root
    - mode: 755
  pkgrepo.managed:
    - humanname: repo-s4a
    - name: deb [signed-by=/etc/apt/keyrings/s4a.gpg trusted=yes arch=amd64] {{ salt['pillar.get']('detector:repo') }} jammy universe
    - file: /etc/apt/sources.list.d/repo-s4a.list
    - clean_file: True

elastic7x_repo:
  cmd.run:
    - name: curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor > /etc/apt/keyrings/elasticsearch.gpg
  file.managed:
    - name: /etc/apt/keyrings/elasticsearch.gpg
    - user: root
    - group: root
    - mode: 755
  pkgrepo.managed:
    - humanname: Elasticsearch 7.x Repo
    - name: deb [signed-by=/etc/apt/keyrings/elasticsearch.gpg arch=amd64] https://artifacts.elastic.co/packages/7.x/apt stable main
    - file: /etc/apt/sources.list.d/elastic-7.x.list
    - clean_file: True

evebox_repo:
  cmd.run:
    - name: curl -fsSL https://evebox.org/files/GPG-KEY-evebox | gpg --dearmor > /etc/apt/keyrings/evebox.gpg
  file.managed:
    - name: /etc/apt/keyrings/evebox.gpg
    - user: root
    - group: root
    - mode: 755
  pkgrepo.managed:
    - humanname: EveBox Debian Repository
    - name: deb [signed-by=/etc/apt/keyrings/evebox.gpg arch=amd64] http://files.evebox.org/evebox/debian stable main
    - file: /etc/apt/sources.list.d/evebox.list
    - clean_file: true

suricata_repo:
  cmd.run:
    - name: add-apt-repository -n -d ppa:oisf/suricata-6.0 --yes

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

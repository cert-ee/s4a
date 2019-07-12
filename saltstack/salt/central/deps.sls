central_elastic5x_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch 5.x Repo
    - name: deb https://artifacts.elastic.co/packages/5.x/apt stable main
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - file: /etc/apt/sources.list.d/elastic-5.x.list

central_mongodb-org_repo:
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse
    - key_url: https://www.mongodb.org/static/pgp/server-4.0.asc
    - file: /etc/apt/sources.list.d/mongodb-org-4.0.list

central_nodejs_repo:
  pkgrepo.managed:
    - humanname: nodejs
    - name: deb https://deb.nodesource.com/node_8.x xenial main
    - key_url: https://deb.nodesource.com/gpgkey/nodesource.gpg.key
    - file: /etc/apt/sources.list.d/nodesource.list

central_influxdata_repo:
  pkgrepo.managed:
    - humanname: influxdata
    - name: deb https://repos.influxdata.com/ubuntu xenial stable
    - keyserver: ha.pool.sks-keyservers.net
    - key_url: https://repos.influxdata.com/influxdb.key
    - file: /etc/apt/sources.list.d/influxdata.list

central_yarn_repo:
  pkgrepo.managed:
    - humanname: yarn
    - name: deb https://dl.yarnpkg.com/debian/ stable main
    - key_url: https://dl.yarnpkg.com/debian/pubkey.gpg
    - file: /etc/apt/sources.list.d/yarn.list

central_s4a_repo:
  pkgrepo.managed:
    - humanname: repo-s4a
    - name: deb [trusted=yes arch=amd64] {{ salt['pillar.get']('detector:repo') }} xenial universe
#    - key_url: {{ salt['pillar.get']('detector:repo') }}/GPG.pub
    - file: /etc/apt/sources.list.d/repo-s4a.list

# Install Oracle Java 8 and other Elasticsearch dependencies
central_dependency_pkgs:
  pkg.installed:
    - refresh: true
    - pkgs:
      - apt-transport-https
      - python-software-properties

central_oracle-ppa:
  pkgrepo.managed:
    - humanname: Oracle Java 8 Repo
    - name: ppa:webupd8team/java
    - keyid: EEA14886
    - keyserver: keyserver.ubuntu.com

central_oracle-license-select:
  cmd.run:
    - name: |
        echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
        echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections

central_oracle-java8-installer:
  pkg.installed:
    - name: oracle-java8-installer
    - refresh: true
    - require:
      - pkgrepo: oracle-ppa
      - cmd: oracle-license-select

central_esnode_limits:
  file.append:
    - name: /etc/security/limits.conf
    - text:
      - elasticsearch - nofile 65535
      - elasticsearch - memlock unlimited
      - root - memlock unlimited

central_vm.swappiness:
  sysctl.present:
    - name: vm.swappiness
    - value: 0

central_vm.max_map_count:
  sysctl.present:
    - name: vm.max_map_count
    - value: 262144

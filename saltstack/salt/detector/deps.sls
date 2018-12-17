{% set api = salt['pillar.get']('detector:api', {'host': '127.0.0.1', 'port': 4000}) %}
{% set int_def = salt['pillar.get']('detector:int_default', ['eth1'] ) %}
{% set connect_test = salt.network.connect(api.host, port=api.port) %}
{% if connect_test.result == True %}
{% 	set int = salt.http.query('http://'+api.host+':'+api.port|string+'/api/network_interfaces/listForSalt', decode=true )['dict']['interfaces'] %}
{% endif %}
{% if int is not defined or int == "" %}
{% 	set int = int_def %}
{% endif %}

elastic5x_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch 5.x Repo
    - name: deb https://artifacts.elastic.co/packages/5.x/apt stable main
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - file: /etc/apt/sources.list.d/elastic-5.x.list

mongodb-org_repo:
  pkgrepo.managed:
    - humanname: mongodb-org
    - name: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse
    - key_url: https://www.mongodb.org/static/pgp/server-3.4.asc
    - file: /etc/apt/sources.list.d/mongodb-org-3.4.list

nodejs_repo:
  pkgrepo.managed:
    - humanname: nodejs
    - name: deb https://deb.nodesource.com/node_8.x xenial main
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
    - name: deb [trusted=yes arch=amd64] https://{{ salt['pillar.get']('detector:repo') }}/ xenial universe
    - key_url: https://{{ salt['pillar.get']('detector:repo') }}/GPG.pub
    - file: /etc/apt/sources.list.d/repo-s4a.list
    - clean_file: True

# Install Oracle Java 8 and other Elasticsearch dependencies
dependency_pkgs:
  pkg.installed:
    - refresh: true
    - pkgs:
      - apt-transport-https
      - python-software-properties
      - python-elasticsearch

oracle-ppa:
  pkgrepo.managed:
    - humanname: Oracle Java 8 Repo
    - name: ppa:webupd8team/java
    - keyid: EEA14886
    - keyserver: keyserver.ubuntu.com

oracle-license-select:
  cmd.run:
    - name: |
        echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
        echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections

oracle-java8-installer:
  pkg.installed:
    - refresh: true
    - require:
      - pkgrepo: oracle-ppa
      - cmd: oracle-license-select

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

{% for val in int %}
capture_interface_{{ val }}:
  network.managed:
    - name: {{ val }}
    - filename: {{ val }}
    - enabled: True
    - type: eth
    - proto: manual
    - rx: off
    - tx: off
    - sg: off
    - tso: off
    - ufo: off
    - gso: off
    - gro: off
    - lro: off
    - required_in: detector_moloch_capture_service
{% endfor %}

# Install Oracle Java 8 and other Elasticsearch dependencies

elastic_pkgs:
  pkg.installed:
    - refresh: True
    - pkgs:
      - apt-transport-https
      - python-software-properties

central_oracle-ppa:
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
    - refresh: True
    - require:
      - pkgrepo: oracle-ppa
      - pkg: elastic_pkgs
      - cmd: oracle-license-select

esnode_limits:
  file.append:
    - name: /etc/security/limits.conf
    - text:
      - elasticsearch - nofile 65536
      - elasticsearch - memlock unlimited
      - root - memlock unlimited

vm.swapiness:
  sysctl.present:
    - value: 0

vm.max_map_count:
  sysctl.present:
    - value: 262144

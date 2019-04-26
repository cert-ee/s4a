# Install Oracle Java 8 and other Elasticsearch dependencies

elastic_pkgs:
  pkg.installed:
    - refresh: True
    - pkgs:
      - apt-transport-https
      - python-software-properties

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

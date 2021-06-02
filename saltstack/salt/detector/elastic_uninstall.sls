elasticsearch_pkg:
  service.dead:
    - name: elasticsearch
    - enable: false
  cmd.run:
    - name: apt-mark unhold elasticsearch
  pkg.purged:
    - name: elasticsearch

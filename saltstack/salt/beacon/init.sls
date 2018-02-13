python-pip:
  pkg.installed:
    - refresh: True

pyinotify:
  pip.installed:
    - upgrade: True
    - require:
      - pkg: python-pip

beacon_restart_minion:
  cmd.run:
    - name: |
        exec 0>&-
        exec 1>&-
        exec 2>&-
        nohup /bin/sh -c 'sleep 10 && salt-call --local service.restart salt-minion' &
    - order: last

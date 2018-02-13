unattended_upgrades_pkg:
  service.dead:
    - name: unattended-upgrades
    - enable: false

unattended_upgrades_conf:
  file.absent:
    - name: /etc/apt/apt.conf.d/20auto-upgrades

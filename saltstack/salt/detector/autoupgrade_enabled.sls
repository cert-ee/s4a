unattended_upgrades_pkg:
  service.running:
    - name: unattended-upgrades
    - reload: true
    - enable: true

unattended_upgrades_conf:
  file.managed:
    - name: /etc/apt/apt.conf.d/20auto-upgrades
    - source: salt://{{ slspath }}/files/autoupgrade/unattended-upgrades.02periodic

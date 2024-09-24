suricata_pkg:
  cmd.run:
    - name: apt-mark unhold suricata
  service.dead:
    - name: suricata
    - enable: false
  pkg.purged:
    - names:
      - suricata

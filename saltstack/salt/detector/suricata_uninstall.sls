suricata_pkg:
  service.dead:
    - name: suricata
    - enable: false
  pkg.purged:
    - names:
      - suricata
      - pfring-dkms
      - pfring-tcpdump
      - pfring-lib

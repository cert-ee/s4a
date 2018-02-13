nfsen_pkg:
  pkg.purged:
    - name: nfsen
  service.dead:
    - name: nfsen
    - enable: false

fprobe_pkg:
  service.dead:
    - name: fprobe
    - enable: false
  pkg.purged:
    - name: fprobe
   
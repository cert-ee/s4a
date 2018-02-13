detector_moloch_pkg:
  service.dead:
    - names:
       - molochcapture
       - molochviewer
    - enable: false
  pkg.purged:
    - name: moloch

moloch_service:
  service.running:
    - enable: true
    - full_restart: true
    - names: 
        - molochviewer
        - molochcapture

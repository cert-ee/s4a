beacons:
  inotify:
  - files:
      /etc/openvpn/keys:
        exclude:
        - /etc/openvpn/keys/.*(crt|key|pem|txt|conf)$:
            regex: true
        mask:
        - create
        - delete
  - disable_during_state_run: true

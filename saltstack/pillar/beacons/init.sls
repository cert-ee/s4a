beacons:
  inotify:
    /etc/openvpn/keys:
      mask:
        - create
      exclude:
        - /etc/openvpn/keys/.*crt$:
            regex: True
        - /etc/openvpn/keys/.*key$:
            regex: True
        - /etc/openvpn/keys/.*pem$:
            regex: True
        - /etc/openvpn/keys/.*txt$:
            regex: True
    disable_during_state_run: True

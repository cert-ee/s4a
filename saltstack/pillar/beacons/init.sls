 beacons:
  inotify:
    - files:
        /etc/openvpn/keys:
          mask:
            - create
          exclude:
            - /etc/openvpn/keys/.*crt$
            - /etc/openvpn/keys/.*key$
            - /etc/openvpn/keys/.*pem$
            - /etc/openvpn/keys/.*txt$
          regex: True
    - disable_during_state_run: True

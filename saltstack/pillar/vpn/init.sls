openvpn:
  saltmaster: salt.example.com
  host: vpn.example.com
  key:
    key_email: noreply@example.com
    key_org: Example-Org
    key_ou: s4a
    key_size: 4096
    makeca: True
  server:
    # Change local to external IP
    local: vpn.example.com 443
    subnet: 192.168.56.0 255.255.255.0
    topology: subnet
    ccd_dir: /etc/openvpn/tcp-443
    ccd_exclusive: False
    dev: tun0
    keepalive: 10 120
    auth: SHA256
    log: /var/log/openvpn.log
    max_clients: 256
    proto: tcp
    status: /var/log/openvpn-status.log
    verb: 1
    cipher: AES-128-CBC
    routes:

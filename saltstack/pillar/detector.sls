detector:
  int_default: 'eth1'
  repo: repo.example.com
  keyserver: keys.example.com
  api:
    host: '127.0.0.1'
    port: '4000'
  vpn:
    org: Example
    email: example@example.com
    server: vpn.example.com
    keys_path: /etc/openvpn
  influxdb:
    host: influx.example.com
    port: 8086
    user: admin
    pass: admin
    proto: https

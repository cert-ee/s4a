# Use "echo 'VerySecurePassword' | openssl passwd -apr1 -stdin" to generate hashes
central:
  es: es.example.com
  htpasswd:
    admin: ''
  influxdb:
    host: influxdb.example.com
    port: 8086
    user: s4a
    pass: it-secure
    proto: https
  chronograf:
    host: influxdb.example.com
    port: 8888

base:
  '*':
    - detector
  'central.*':
    - vpn.easy-rsa.config
    - beacon
    - central.bundle
  'es.*':
    - elastic.single
  'influx.*':
    - influx
  'vpn.*':
    - vpn
  'keys.*':
    - sks.config
  'repo.*':
    - repo
  'docs.*':
    - docs

base:
  '*':
    - detector
  'central.*':
    - vpn
    - beacons
    - central
    - central.le
  'influxdb.*':
    - kapacitor
    - chronograf
  'vpn.*':
    - vpn
  'docs.*':
    - central.le

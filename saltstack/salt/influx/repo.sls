influxdata_repo:
  pkgrepo.managed:
    - humanname: InfluxDB Repo
    - name: deb https://repos.influxdata.com/ubuntu {{ salt['grains.get']('oscodename') }} stable
    - key_url: https://repos.influxdata.com/influxdb.key
    - file: /etc/apt/sources.list.d/influxdata.list

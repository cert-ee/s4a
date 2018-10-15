---
kapacitor:
  https_enabled: "false"
  cert: /etc/ssl/kapacitor.pem
  influxdb:
    host: influxdb.example.com
    port: 8086
    user: s4a
    password: it-secure
    proto: https
  smtp:
    enabled: "false"
    host: localhost
    port: 25
    user: ""
    pass: ""
    from: root@localhost
  slack:
    enabled: "false"
    default: "false"
    workspace: ""
    hook_url: ""
    channel: ""
    global: "false"
    state_changes_only: "false"

# S4A

Suricata for All (S4A) is a distributed intrusion detection system (IDS). It utilizes open source software components to monitor, analyse and capture network traffic to detect possible intrusions.

Docs are located at: [docs.s4a.cert.ee](https://docs.s4a.cert.ee)


## Reactor definition in /etc/salt/master for vpn/easy-rsa stuff:
```yaml
- 'vpn/s4a/serial':
  - /srv/reactor/vpn.sls
```
## Reactor definition in /etc/salt/master for vpn/easy-rsa client cert autosigning:
```yaml
- 'salt/beacon/*/inotify//etc/openvpn/keys':
  - /srv/reactor/sign_crt.sls
```

## Credits

Without the following open source products, this project would not have been possible:

* Suricata - Intrusion detection system.

  * [https://suricata-ids.org/](https://suricata-ids.org/)

* Evebox - Web based alert and event management tool for events generated by the Suricata network threat detection engine [https://evebox.org](https://evebox.org)

* Netdata - a system for distributed real-time performance and health monitoring. In this project itis meant for independent health monitoring of detector installations.

  * [https://github.com/firehol/netdata](https://github.com/firehol/netdata)

* nfsen - NfSen is a graphical web based application for the nfdump netflow tool. . Lightweight traffic analysis tool to substitute Moloch.

  * [http://nfsen.sourceforge.net/](http://nfsen.sourceforge.net/)

* Moloch - Moloch is an open source, large scale, full packet capturing, indexing and database system.

    * [https://github.com/aol/moloch](https://github.com/aol/moloch)

* OpenVPN - Open Source VPN software.

  * [https://openvpn.net/](https://openvpn.net/)

* Elasticsearch - Elasticsearch is a Lucene based distributed full-text search and analytics engine designed for horizontal scalability, maximum reliability, and easy management. 

  * [https://www.elastic.co/products/elasticsearch](https://www.elastic.co/products/elasticsearch)

* Telegraf - Telegraf is a metrics reporting agent written in Go for collecting, processing, aggregating and sending metrics to InfluxDB.

  * [https://github.com/influxdata/telegraf](https://github.com/influxdata/telegraf)

* InfluxDB - Time Series Database Monitoring & Analytics
  
  * https://www.influxdata.com/

* Grafana - The open platform for beautiful analytics and monitoring

  * https://grafana.com/

* Loopback - Web interface to manage detector settings and other aspects. Communication with salt and web interface is done via loopback connected to a MongoDB database.

    * [https://github.com/strongloop/loopback](https://github.com/strongloop/loopback)

* SaltStack - Configuration management and orchestration for both detector and central components
    * [https://saltstack.com/]

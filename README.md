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

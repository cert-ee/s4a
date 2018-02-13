grafana_repo:
  pkgrepo.managed:
    - humanname: Grafana Repo
    - name: deb https://packagecloud.io/grafana/stable/debian/ jessie main
    - key_url: https://packagecloud.io/gpg.key
    - file: /etc/apt/sources.list.d/grafana.list

grafana:
  pkg.installed:
    - refresh: True
    - require:
      - pkgrepo: grafana_repo
  service.running:
    - name: grafana-server
    - enable: True

#
# Note:
# Detector most probably runs single node cluster, shouldn't
# we put reconfigure it right after install?
#  curl -XPUT 'localhost:9200/_settings' -d '{ "index" : { "number_of_replicas" : 0 } }'
#

include:
  - detector.deps

elasticsearch:
  pkg.installed:
    - version: 5.6.0
    - hold: true
    - update_holds: true
    - refresh: true
    - require:
      - pkgrepo: elastic5x_repo
      - pkg: dependency_pkgs
  service.running:
    - enable: true
    - full_restart: true
    - watch:
      - pkg: elasticsearch
      - file: elasticsearch_yml

elasticsearch_dirs:
  file.directory:
    - user: elasticsearch
    - group: elasticsearch
    - dir_mode: 755
    - file_mode: 644
    - makedirs: true
    - names:
      - /etc/elasticsearch
      - /etc/elasticsearch/scripts
      - /srv/elasticsearch
      - /var/log/elasticsearch
      - /var/run/elasticsearch
    - require:
      - pkg: elasticsearch

elasticsearch_yml:
  file.managed:
    - name: /etc/elasticsearch/elasticsearch.yml
    - source: salt://{{ slspath }}/files/elastic/elasticsearch.yml.jinja
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - template: jinja
    - require:
      - file: elasticsearch_dirs

elasticsearch_jvm_options:
  file.managed:
    - name: /etc/elasticsearch/jvm.options
    - source: salt://{{ slspath }}/files/elastic/jvm.options.jinja
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - template: jinja
    - require:
      - file: elasticsearch_dirs
    - watch_in:
      - service: elasticsearch

elasticsearch_defaults:
  file.managed:
    - name: /etc/default/elasticsearch
    - source: salt://{{ slspath }}/files/elastic/default_elasticsearch.jinja
    - user: root
    - group: root
    - mode: 750
    - template: jinja

elasticsearch_cron:
  file.managed:
    - name: /etc/cron.daily/elasticsearch
    - source: salt://{{ slspath }}/files/elastic/elasticsearch.cron
    - user: root
    - group: root
    - mode: 750
    - template: jinja

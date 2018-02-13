# Install standalone elasticsearch 5.x instance
include:
  - elastic

elasticsearch:
  service.running:
    - enable: True
    - watch:
      - file: /usr/lib/systemd/system/elasticsearch.service
      - pkg: elastic_pkg
      - file: /etc/elasticsearch/elasticsearch.yml

elastic_single_dirs:
  file.directory:
    - user: elasticsearch
    - group: elasticsearch
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - names:
      - /etc/elasticsearch
      - /etc/elasticsearch/scripts
      - /srv/elasticsearch
      - /var/log/elasticsearch
      - /var/run/elasticsearch
    - require:
      - pkg: elastic_pkg

/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - source: salt://elastic/files/elasticsearch_single.yml.jinja
    - user: elasticsearch
    - group: elasticsearch
    - mode: 750
    - template: jinja
    - require:
      - file: elastic_single_dirs

/etc/default/elasticsearch:
  file.managed:
    - source: salt://elastic/files/default_elasticsearch_single.jinja
    - user: root
    - group: root
    - mode: 750
    - template: jinja
    - defaults:
        java_opts: 30

/etc/elasticsearch/log4j2.properties:
  file.managed:
    - source: salt://elastic/files/log4j2.properties.jinja
    - user: elasticsearch
    - group: elasticsearch
    - mode: 640
    - require:
      - file: elastic_single_dirs

/usr/lib/systemd/system/elasticsearch.service:
  file.managed:
    - source: salt://elastic/files/elasticsearch.service.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja

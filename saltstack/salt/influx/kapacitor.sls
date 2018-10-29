include:
  - influx.repo

central_kapacitor_pkg:
  pkg.installed:
    - name: kapacitor
    - refresh: true
    - require:
      - pkgrepo: influxdata_repo

central_kapacitor_service:
  service.running:
    - name: kapacitor
    - watch:
      - pkg: central_kapacitor_pkg
      - file: central_kapacitor_conf
    - enable: true

central_kapacitor_conf:
  file.managed:
    - name: /etc/kapacitor/kapacitor.conf
    - source: salt://{{ slspath }}/files/kapacitor/kapacitor.conf.jinja
    - user: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja
    - require:
      - pkg: central_kapacitor_pkg

central_kapacitor_task:
  file.recurse:
    - name: /etc/kapacitor/load/
    - source: salt://{{ slspath }}/files/kapacitor/load/
    - makedirs: True
    - require:
      - pkg: central_kapacitor_pkg

central_kapacitor_load:
  cmd.run:
    - shell: /bin/bash
    - name: |
        export KAPACITOR_DIR=/etc/kapacitor/load
        for f in $KAPACITOR_DIR/*.tick
        do
            name="$(basename $f)"
            name="${name/.tick/}"
            kapacitor define $name \
                -type stream \
                -dbrp telegraf.autogen \
                -tick $f
            kapacitor enable $name
        done
    - require:
      - service: central_kapacitor_service
    - onchanges:
      - pkg: central_kapacitor_pkg

include:
  - docs.nginx

docs_pkgs:
  pkg.latest:
    - refresh: True
    - pkgs:
      - python-pip
      - python-sphinx

docs_pip_pkgs:
  pip.installed:
    - pkgs:
      - sphinx-autobuild
      - recommonmark
      - sphinx_rtd_theme
    - require:
      - pkg: docs_pkgs

docs_git_source:
  file.recurse:
    - name: /tmp/s4a-docs
    - source: salt://{{ slspath }}/files/s4a-docs
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644

docs_build_html:
  cmd.run:
    - name: make html
    - cwd: /tmp/s4a-docs
    - runas: root
    - require:
      - file: docs_git_source

docs_publish:
  cmd.run:
    - name: rsync --delete -a _build/html/ /srv/{{ grains['fqdn'] }}/www/
    - cwd: /tmp/s4a-docs
    - runas: root
    - require:
      - file: docs_git_source
      - sls: docs.nginx

include:
  - repo.nginx

reprepro:
  pkg.installed:
    - refresh: True
    - pkgs:
      - reprepro

repo_dir:
  file.directory:
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - recurse:
      - mode
    - names:
      - /srv/{{ grains['fqdn'] }}/repositories
      - /srv/{{ grains['fqdn'] }}/repositories/conf

repo_conf:
  file.recurse:
    - name: /srv/{{ grains['fqdn'] }}/repositories/conf
    - source: salt://{{ slspath }}/files/repo/conf
    - file_mode: 644
    - dir_mode: 755
    - template: jinja
    - require: 
      - file: repo_dir

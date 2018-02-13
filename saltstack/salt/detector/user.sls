cert:
  group:
    - present
  user.present:
    - fullname: CERT Access
    - gid_from_name: True
    - shell: /bin/bash
    - groups:
      - sudo
      - adm
      - dip
      - cdrom
      - plugdev

cert_key:
  ssh_auth.present:
    - user: cert
    - names:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtu3mhkM6xzKNbT8+4UOUwSvcvYZO7oIaTkGK30M1jJ root@salt
    - comment: CERT-EE access account enabled with VPN option
    - require:
      - user: cert

cert_sudoers:
  file.managed:
    - name: /etc/sudoers.d/cert
    - source: salt://{{ slspath }}/files/user/sudoers_template.jinja
    - user: root
    - group: root
    - mode: 440
    - template: jinja
    - defaults:
        sudouser: cert
        commands: 'ALL'
    - require:
      - user: cert

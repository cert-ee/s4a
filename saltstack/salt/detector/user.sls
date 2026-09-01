cert:
#  group:
#    - present
  user.present:
    - fullname: CERT Access
    - usergroup: True
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
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD3ZysNQ3J8euiyJkFSmnxmw5AQ8VeeoH4001YK3kdSFjWHKxYbGNkE3iE+44IXwQZLA/yfOyNtZxT6fxTsHk7i5IdXbEfjgFtvUJjFuwwVFK2wZYILnxSRWWfmY1oZGge1yU2u6jNhUCsASo6EOdI9XMAjuZgbyrajbfF/L2AwtI3Qjfh8l2VpHLQZwt3jHO1nAm6WAuHQx8iQivg8b7YPP6IcA0hMDLTzg9sw+tGIXmEmGBYxiTtaSxWlGwGw7VyWk7+RlaUTjbFpmlkvVYk7C+jMYJCFd12YRNhZME+Cm+3+rGLUrddttErrLtFSiFTNzN0VOtVfIyBur3TTVZXL+gnkvDajkVF2bykMo8Jf3LCT0HYabSwllTjBZMsE9mqWfLH/ZPpuGICe7IUmTHdem/07CsD80MIlOoa1YtLyiZ0Eq2AtikWDGpJThOWUq8fajfzZeZXUUN1ubsZbtnobtAzMfDSOrlKEcYt9CJkClK90UhvJk68BcL/5L4AvSxF1VrfnFndetipym7KgXk4uPyYClSuecHdIpfCjDEmQhpfHalnAb3SXkckhheOgnzZdWaFEgvMfQufC98iNzKjQbtcOgLLRSkKcrLhF69O73u1xjIwIYiW/8t6p9HmB+do7tALfSQIdz/N4ZLKPmGybIuu5dbwTtT9qSK4RTfJrEw==
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5kedPV+YiJ5/x4Z2gHqgRuA8VWQ+4bwF5NZ2GwCn3O/agcKesOr9J0wMibuLVr+TM93rK7mXmd0FmF7j2WiN05MFhj6YaNGGhFZsM82Lp7ZUsVfCwaetCoMMpQWhj61XePNgNjDVACPH8VpxVc/7anQlDBH6+fuP+0hQAlb0VDD7eCToJhs9PIDW0B7yQp/ykswTwFCPuNeyVExxwOFW/QUVs79ECL+goSFXrwyNMSIzt3Z3Gv+9z9t53W3LTERp1hgbCpABa3sAvYB8T6RK1SGcNhOYGCG432x1i0Uj9sgma908tzxa+6LSJPti7yE1jc3LTrko6ff73hGlblHlemuw0BdRfSt4JgLsnMFP2QFEKB/w1n42E0W3LSdiA6LCkPRRxVC+YAauqc0hm7mcZP+vfRmXk0uDG0rP6WFprki1ZkQgYMIxBvn9YbEJKwD4JlapSzGq4ZoekgQ63KJsHKBxfrvT0ridST3K9s7uubN6sbxj/hJuQpmlOcllbRkDDkrXhNTGhXa75gYvWxypR0cc/Xeg+DsXuQNKOtmKMQ/Dc7lr5JMjiuam8EwkslmmXX2BqckQlH+uyGmofIOvKipWnj/7mvoemdc3NtAv0ozPE1swJaBjws5EV188A1NBL5Rjc3OLBAclt9HFbGp2XABnRih4485I/qsvQcJ+50Q==
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

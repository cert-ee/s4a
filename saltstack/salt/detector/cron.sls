# Set a daily cron job to auto apply all salt states for components that are installed and enabled
detector_salt_cron:
  file.managed:
    - name: /etc/cron.daily/salt.sh
    - source: salt://{{ slspath }}/files/cron/cron.jinja
    - template: jinja
    - mode: 750

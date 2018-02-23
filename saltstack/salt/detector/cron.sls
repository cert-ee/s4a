# Set a daily cron job to auto apply all salt states for components that are installed and enabled
detector_salt_cron:
  file.managed:
    - name: /etc/cron.daily/auto_detector_states.py
    - source: salt://{{ slspath }}/files/cron/auto_detector_states.py
    - mode: 750

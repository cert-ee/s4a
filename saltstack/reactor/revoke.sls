vpn_revoke:
  runner.state.orchestrate:
    - name: vpn.write_revoke
      args:
        - mods: vpn.write_revoke
        - pillar:
            event_data: {{ data['data'] | tojson }}

vpn_certs:
  runner.state.orchestrate:
    - kwarg:
        mods: vpn.orch
        pillar:
          event_data: {{ data['data'] | json() }}

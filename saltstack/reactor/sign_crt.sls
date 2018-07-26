sign_certs:
  runner.state.orchestrate:
    - kwarg:
        mods: vpn.easy-rsa.orch_certs
        pillar:
          event_data: {{ data | json() }}

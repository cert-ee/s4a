sign_certs:
  runner.state.orchestrate:
    - vpn.easy-rsa.orch_certs
    - pillar:
       event_data: {{ data | json() }}
#
#    - kwarg:
#        mods: vpn.easy-rsa.orch_certs
#        pillar:
#          event_data: {{ data | json() }}

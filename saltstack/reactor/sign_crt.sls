sign_certs:
  runner.state.orchestrate:
    - name: vpn.easy-rsa.orch_certs
      args: 
        - mods: vpn.easy-rsa.orch_certs
        - pillar:
            event_data: {{ data | tojson }}

#!/bin/bash
curl -s -H "Accept: application/json" -H "Content-Type:application/json" -XPUT "http://localhost:9200/_template/suricata" -d @/etc/evebox/suricata-template-6.8.json

#!/bin/bash

username=$1
[[ $2 != "admin" ]] && admin="false" || admin="true"

if [ "x$username" == "x" ] ; then
	echo "Usage: $0 <username> [admin|user]"
	exit
fi
echo ${admin:-true}
curl -s -XPOST -H "Content-Type: application/x-ndjson" http://localhost:9200/_bulk --data-binary '{"index": {"_index": "users", "_type": "user", "_id": "'$username'"}}
{"removeEnabled":false,"userName":"'$username'","emailSearch":false,"enabled":true,"webEnabled":true,"headerAuthEnabled":true,"createEnabled":'${admin}',"settings":{},"passStore":"","userId":"'$username'"}
' | jq ''

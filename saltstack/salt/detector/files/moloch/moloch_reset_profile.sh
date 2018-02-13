#!/bin/bash

username=$1

if [ "x$username" == "x" ] ; then
	echo "Usage: $0 <username>"
	exit
fi

curl -s -XPOST -H "Content-Type: application/x-ndjson" http://localhost:9200/_bulk --data-binary '{"index": {"_index": "users", "_type": "user", "_id": "'$username'"}}
{"removeEnabled":false,"userName":"'$username'","emailSearch":false,"enabled":true,"webEnabled":true,"headerAuthEnabled":true,"createEnabled":true,"settings":{},"passStore":"","userId":"'$username'"}
' | jq ''

#!/bin/bash

username=$1
admin=false
enabled=false

while [ ! -z $2 ] ; 
do
	[[ $2 == "admin" ]] && admin="true" && enabled="true"
	[[ $2 == "read"  ]] && enabled="true"
	shift
done

if [ "x$username" == "x" ] ; then
	echo "Usage: $0 <username> [admin] [read]"
	exit
fi

curl -s -XPOST -H "Content-Type: application/x-ndjson" http://localhost:9200/_bulk --data-binary '{"index": {"_index": "arkime_users", "_type": "_doc", "_id": "'$username'"}}
{"removeEnabled":false,"userName":"'$username'","emailSearch":true,"enabled":'$enabled',"webEnabled":true,"headerAuthEnabled":true,"createEnabled":'${admin}',"settings":{},"passStore":"","userId":"'$username'"}
' | jq ''

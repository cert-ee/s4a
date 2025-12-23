#!/bin/bash
#
# Custom calculations to set RETAINNUMDAYS
#
# Define custom reserved disk space and amount of Suricata logs to keep in /etc/s4a-detector/custom_elastic_cleanup.conf
# To define custom reserverd disk space use conf parameter elasticFreeSpaceReserved with a value of reserverd GigaBytes.
# To define custom days to keep Suricata logs use conf parameter suricataLogsToKeep with a value of days to keep logs.
#
# Example content of /etc/s4a-detector/custom_cleanup.conf: 
# elasticFreeSpaceReserved=500
# suricataLogsToKeep=30
# esReplicas=2

if [[ "$(ps -ef | grep /opt/arkime/db/db.pl | grep -v grep | awk '{print $8}')" == "/opt/arkime/db/db.pl" ]]
then
	exit 1
fi

# Initalize variables
export LC_ALL=C

getArkimeSessionsSize() {
sizes=""
nr=""
arkimeAverageSession=""

# We need bc for non integer calculations and jq for parsing json
apt-get -q -y install bc jq >>/dev/null

# Get number of available indexes
nr="$(curl --silent -XGET "$ESHOSTPORT/_cat/indices?v&pretty" --stderr - | grep -oE '(arkime_sessions.*|sessions.*)-[0-9]{6}' | tr '\n' ' ' | sed 's/ $//')"

# Get index sizes in bytes
for x in $nr
do
    sizes+=" $(curl --silent -XGET "$ESHOSTPORT/$x/_stats" | jq ".indices[\"$x\"].total.store.size_in_bytes // empty" 2>/dev/null)"
done

# Get average of all returned index sizes
average=`echo $sizes | jq -s 'add/length'`

# Convert average to GB
arkimeAverageSession=$(echo $average | awk -v OFMT='%f' '{ byte =$1 /1024/1024/1024; print byte}')

# Make sure that arkimeAverageSession is not zero
#if [ $arkimeAverageSession -eq 0 ] ; then
#    arkimeAverageSession=1
#fi
}

removeSuricataLogs() {

if [ -z $eveLogsToKeep ] && [ -z $suricataLogsToKeep ]
then
	suricataLogsToKeep=91

elif [ $eveLogsToKeep ]
then
        suricataLogsToKeep=$eveLogsToKeep
fi

suricataLogs="$(curl --silent -XGET "$ESHOSTPORT/_cat/indices?v&pretty" --stderr - | grep -oE 'suricata.*-[0-9]{4}\.[0-9]{2}\.[0-9]{2}' | sort)"
suricataLogCount=$(wc -w <<< "$suricataLogs")
suricataLogsDeleteCount=$(bc <<< "$suricataLogCount - $suricataLogsToKeep")

if [ $suricataLogsDeleteCount -ge 0 ]
then
        for log in $(head -n $suricataLogsDeleteCount <<< "$suricataLogs");
        do
                echo -n "Removing $log "

                deleteStatus="$(curl --silent -XDELETE "$ESHOSTPORT/$log")"

                if [ $(grep acknowledged <<< "$deleteStatus") ]
                then
                echo "done"
                else
                echo "fail"
                fi
        done
fi
}

getSuricataSize() {

sum=""
suricataSize=""
sizes=""

suricata="$(curl --silent -XGET "$ESHOSTPORT/_cat/indices?v&pretty" --stderr - | grep -oE 'suricata.*-[0-9]{4}\.[0-9]{2}\.[0-9]{2}' | tr '\n' ' ' | sed 's/ $//')"

# Get index sizes in bytes
for x in $suricata
do
    sizes+=" $(curl --silent -XGET "$ESHOSTPORT/$x/_stats" | jq ".indices[\"$x\"].total.store.size_in_bytes // empty" 2>/dev/null)"
done

# Get sum of all returned index sizes
sum=`echo $sizes | jq -s 'add'`

# Convert sum bytes to GB
suricataSize=$(echo $sum | awk -v OFMT='%f' '{ byte =$1 /1024/1024/1024; print byte}')
}

######################## End of Functions ##########################

ESHOSTPORT=http://127.0.0.1:9200
customSettings=/etc/s4a-detector/custom_cleanup.conf

if [ -r $customSettings ]
then
        source $customSettings
fi

getArkimeSessionsSize
removeSuricataLogs
getSuricataSize

# Get disk size in GB of disk where /srv is mounted
if ! mountpoint /srv/elasticsearch > /dev/null 2>&1 && [[ "$(df | grep -E '/srv/es[0-9]+' -c)" != "0" ]]
then
	multinodes="true"
	echo -n "Elaticsearch mountpoints: "
	disk=0
        for espart in $(df | grep /srv/es | awk '{print $6}')
        do
                echo -n "$espart "
                disk=$(( $(df -BG --output=size $espart | tail -n 1 | grep -oP '\d+(?=G)') + $disk ))
        done

	echo
	echo "Elasticsearch storage available $disk GB"

elif mountpoint /srv/elasticsearch > /dev/null 2>&1
then
	echo -n "Elaticsearch mountpoint: "
	disk=`df -BG --output=size /srv/elasticsearch | tail -n 1 | grep -oP '\d+(?=G)'`
	echo "/srv/elasticsearch $disk GB"

elif mountpoint /srv > /dev/null 2>&1
then
	echo -n "Elaticsearch mountpoint: "
	disk=`df -BG --output=size /srv | tail -n 1 | grep -oP '\d+(?=G)'`
	echo "/srv $disk GB"
else
        echo -n "Free disk space - /srv/elasticsearch folder: "
        disk="$(( $(df -BG --output=size / | tail -n 1 | grep -oP '\d+(?=G)') - $(df -BG --output=avail / | tail -n 1 | grep -oP '\d+(?=G)') - $(du -s --block-size=1G /srv/elasticsearch/ | awk '{print $1}') ))"
        echo "$disk GB"
fi

# Add in a reserve

if [ $elasticFreeSpaceReserved ]
then
	if [[ $elasticFreeSpaceReserved =~ [0-9] ]] && [[ $elasticFreeSpaceReserved -gt 0 ]]
	then
		available=$(( $disk - $elasticFreeSpaceReserved))
	fi
fi

# If custom reserve is not defined add 15% or 20% of disk size depending if /srv/elasticsearch is a separate partition or not. 
if [ -z $available ] && [[ "$multinodes" == "true" ]]
then
	if [ "$esReplicas" ]
	then
	replicas=$esReplicas
	else
        replicas=1
	fi
	available=$(( $disk - $(printf "%.0f\n" $(echo "$disk * 0.15" | bc)) ))
elif [ -z $available ]
then
        if mountpoint /srv/elasticsearch > /dev/null 2>&1
        then
                replicas=0
                available=$(( $disk - $(printf "%.0f\n" $(echo "$disk * 0.15" | bc)) ))
        else
                replicas=0
                available=$(( $disk - $(printf "%.0f\n" $(echo "$disk * 0.20" | bc)) ))
        fi
elif [[ "$multinodes" == "true" ]] && [ "$esReplicas" ]
	then
        replicas=$esReplicas
elif [[ "$multinodes" == "true" ]]
        then
        replicas=1
else
        replicas=0
fi

# Final number of days to keep indexes (-1 day because db.pl is not considering current day)
RETAINNUMDAYS=$(echo "($available - $suricataSize) / $arkimeAverageSession - 1"|bc)

# Check if indexes are in readonly state
# and disable readonly state if 2GB or more disk space is available

if [ "$(curl -s -XGET $ESHOSTPORT/_all/_settings | grep read_only_allow_delete.:.true)" ];
then
	echo "WARNING: Elastic is in read only mode"
	if [[ $(df -BG --output=avail /srv/elasticsearch | tail -n 1 | grep -oP '\d+(?=G)') -ge 2 ]]
	then
		echo -n "Disabling Elastic read only mode: "
		curl -s -XPUT -H "Content-Type: application/json" $ESHOSTPORT/_all/_settings -d '{"index.blocks.read_only_allow_delete": null}' >>/dev/null
		if [ $? == 0 ]
		then
			echo "done"
		else
			echo "failed"
		fi
	else
		echo "ERROR: Cannot disable read only mode. Not enough free disk space"
		exit 1
	fi
fi

# Delete old Arkime session indexes
/opt/arkime/db/db.pl $ESHOSTPORT expire daily $RETAINNUMDAYS --nooptimize
sessionDeleteSuccess=$?

# Optimize Arkime indexes between 5AM and 7AM.
if [[ "$(date "+%H:%M")" > "05:30" ]] && [[ "$(date "+%H:%M")" < "06:30" ]]
then
	/opt/arkime/db/db.pl $ESHOSTPORT expire daily $RETAINNUMDAYS
fi

# Sync PCAPs
esNode="$(curl -s $ESHOSTPORT/_cluster/health | jq -r '.cluster_name')"
if [ ! -z "$esNode" ] && [[ $esNode = "$(echo "$esNode" | grep -oE "^[0-9a-zA-Z\.-]+")" ]]
then
        /opt/arkime/db/db.pl $ESHOSTPORT sync-files $esNode /srv/pcap/
fi

# Set replica count
curl -s -XPUT "$ESHOSTPORT/*/_settings?pretty" -H 'Content-Type:application/json' -d'{ "index" : { "number_of_replicas" : '$replicas' }}' >/dev/null
curl -s -XPUT "$ESHOSTPORT/.logs-deprecation.elasticsearch-default/_settings" -H 'Content-Type: application/json' -d'{ "index" : { "number_of_replicas" : '$replicas' } }' >/dev/null

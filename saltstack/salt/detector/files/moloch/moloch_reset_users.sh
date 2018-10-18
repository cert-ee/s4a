#!/bin/bash

. /etc/default/s4a-detector

mongo_query='
	db.getCollection("user").aggregate([
	        { $lookup: { from: "roleMapping", localField: "_id", foreignField: "principalId", as: "mapping" }},
	        { $match: { "roleMapping.0": { $exists: false } } },
		{ $unwind: { path: "$mapping", preserveNullAndEmptyArrays: true } },
		{ $lookup: { from: "role", localField: "mapping.roleId", foreignField: "_id", as: "roles" }},
		{ $match: { "role.0": { "$exists": false } } },
		{ $unwind: { path: "$roles", preserveNullAndEmptyArrays: true } }
	]).forEach( function (doc) { if (doc.roles) print (doc.username + " " + doc.roles.name); else print (doc.username + " none"); });'

mongo_result=`mongo --quiet --authenticationDatabase admin -u $MONGODB_USER -p $MONGODB_PASSWORD $MONGODB_DATABASE --eval "$mongo_query"`

if [ $? == 0 ] ; then
	IFS_bak="$IFS"
	IFS=$'\n'
	for user_data in $mongo_result
	do
		IFS="$IFS_bak"
		/usr/local/bin/moloch_reset_profile.sh $user_data
	done
else
	echo "MongoDB error"
fi

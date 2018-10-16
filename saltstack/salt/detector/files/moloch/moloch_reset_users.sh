#!/bin/bash

. /etc/default/s4a-detector

mongo_query='
	db.getCollection("roleMapping").aggregate([
	        { $lookup: { from: "user", localField: "principalId", foreignField: "_id", as: "user" }},
        	{ $unwind: "$user" },
	        { $lookup: { from: "role", localField: "roleId", foreignField: "_id", as: "role" }},
        	{ $unwind: "$role" },
	]).forEach( function (doc) { print (doc.user.username + " " + doc.role.name);});'

mongo_result=`mongo --quiet --authenticationDatabase admin -u $MONGODB_USER -p $MONGODB_PASSWORD $MONGODB_DATABASE --eval "$mongo_query"`

IFS_bak="$IFS"
IFS=$'\n'
for user_data in $mongo_result
do
	IFS="$IFS_bak"
	/usr/local/bin/moloch_reset_profile.sh $user_data
done

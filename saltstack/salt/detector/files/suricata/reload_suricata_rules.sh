#!/bin/bash

ruleFeedsPath=/srv/s4a-detector/suricata
suricataRules=/etc/suricata/rules/all.rules
suricataLog=/var/log/suricata/suricata.log
disabledSids=$ruleFeedsPath/rules_disabled.txt
disabledSidsCustom=$ruleFeedsPath/rules_disabled_custom.txt
ruleStatus=$ruleFeedsPath/rules_status.json

tmpPath=$ruleFeedsPath/rules/.tmp
tmpRulesStage1=$tmpPath/rules_stage1.rules
tmpRulesStage2=$tmpPath/rules_stage2.rules
tmpDisabledSids=$tmpPath/rules_disabled.txt

fixMultilineRules() {
	sed -r 's/\\\ $/\\/' | sed  -r ':a ;$! N; s/\\\n//; ta ; P ; D'
}

getCentralRulesets() {
source /etc/default/s4a-detector
mongosh $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval 'db.feed.find();'| grep filename|cut -d"'" -f2 | sed 's/\.tar\.gz//' | xargs|sed 's/ /\|/g'
}

extractRules() {
if [ -f $tmpRulesStage1 ]; then rm $tmpRulesStage1; fi

for filename in $(find $1 -type f -name "*.tar.gz")
do
echo -n "Proccessing $filename: " >&2
ruleset=$(sed -e 's/^.*\///' -e 's/.tar.gz$//' <<< $filename)

mkdir -p $tmpPath/$ruleset
tar zxf $filename -C $tmpPath/$ruleset/
	for ruleFile in $(find $tmpPath/$ruleset/ -type f -name "*.rules")
	do
	echo -n "."
	cat $ruleFile | fixMultilineRules | grep ^alert >> $2

	if [[ "$ruleset" =~ ($centralRulesets) ]];
	then
	continue
	else
	customSids+=$(grep -oE sid:[0-9]+ $ruleFile | grep -v "^\#")
	fi

	done
echo "done"
done
}

deduplicateRules() {

	cat $disabledSidsCustom $disabledSids 2> /dev/null | sed '/^$/d' | sort -u >> $tmpDisabledSids
	grep -wvf <(sed -r "s/#.*.$//" $tmpDisabledSids | grep -oE '[0-9]+' | sed 's/^/sid:/') $1 | sort -u
}

reloadSuricata() {
	kill -USR2 $(pgrep -f /usr/bin/suricata)
}

cleanup() {
        if [ ! -z $tmpPath ] && [ -d $tmpPath ]
        then
        echo -n "Cleaning up: "
        rm -rf $tmpPath
        echo " done"
        fi
}

checkErrors() {
lastReloadTimestamp="$(grep "Loading rule file" $suricataLog | sed 's/ - <Config>.*.$//' | tail -n1)"
invalidSignatures="$(grep "$lastReloadTimestamp" -A 1000 $suricataLog | grep ERR_INVALID_SIGNATURE | grep -oE 'sid:[0-9]+' |cut -d: -f2| sort -u)"
invalidSignaturesCount=$(wc -l <<< $invalidSignatures)
}


printRuleStatus() {

if [ "$1" == "init" ]
then
printf '{"rules_count":0,"rules_count_custom":0,"rules_count_enabled":0,"invalid_signatures_count":0,"invalid_signatures":[]}'
else
customRuleCount=$(sed '/^$/d' <<< "${customSids[@]}" | grep -vf $tmpDisabledSids | wc -l)
allRulesCount=$(grep -oE sid:[0-9]+ $tmpRulesStage1 -c)
rulesDisabledCount=$(cat $tmpDisabledSids|wc -l)
rulesEnabledCount=$(grep -oE sid:[0-9]+ $suricataRules -c)
printf '{"rules_count":'$allRulesCount',"rules_count_custom":'$customRuleCount',"rules_count_enabled":'$rulesEnabledCount',"invalid_signatures_count":'$invalidSignaturesCount',"invalid_signatures":['$(xargs <<< $invalidSignatures|sed -e 's/ /,/g')']}'
fi
}

####### MAIN #########

if [ ! -f "$ruleStatus" ] || [ "$1" == "init" ]
then
echo "Initializing $ruleStatus"

if [ ! -d $ruleFeedsPath/rules ]
then
mkdir -p $ruleFeedsPath/rules
fi

printRuleStatus init > $ruleFeedsPath/rules_status.json
chown s4a: -R $ruleFeedsPath/
exit 0
fi

if [ $(find /srv/s4a-detector/suricata/rules/ -name "*.tar.gz" -type f | wc -l) -gt 0 ]
then
customSids=()
centralRulesets="$(getCentralRulesets)"

echo "Extracting signatures from $ruleFeedsPath/rules:"
	extractRules "$ruleFeedsPath/rules/" $tmpRulesStage1

echo -n "Deduplicating signatures: "
	deduplicateRules $tmpRulesStage1 > $tmpRulesStage2
echo "done"

echo -n "Deploying signatures to $suricataRules: "
	mv $suricataRules $suricataRules.bak
	cp $tmpRulesStage2 $suricataRules
	reloadSuricata
echo "done"

echo -n "Checking for Invalid Signatures: "
sleep 30
checkErrors
echo "found $invalidSignaturesCount"

echo -n "Generating rule status: "
printRuleStatus > $ruleFeedsPath/rules_status.json

echo "done"

cleanup

fi

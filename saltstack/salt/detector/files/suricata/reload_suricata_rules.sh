#!/bin/bash

ruleFeedsPath=/srv/s4a-detector/suricata
suricataRules=/etc/suricata/rules/all.rules
disabledSids=$ruleFeedsPath/rules_disabled.txt

tmpPath=$ruleFeedsPath/rules/.tmp
tmpRulesStage1=$tmpPath/rules_stage1.rules
tmpRulesStage2=$tmpPath/rules_stage2.rules

fixMultilineRules() {
	sed -r 's/\\\ $/\\/' | sed  -r ':a ;$! N; s/\\\n//; ta ; P ; D'
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
	done
echo "done"
done
}

deduplicateRules() {
	grep -wvf <(sed -r "s/#.*.$//" $disabledSids | grep -oE '[0-9]+' | sed 's/^/sid:/') $1 | sort -u
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

####### MAIN #########

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

cleanup

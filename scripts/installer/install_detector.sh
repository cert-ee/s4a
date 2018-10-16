#!/bin/bash

SALT_BOOTSTRAP="https://bootstrap.saltstack.com"
GIT_REPO_HOST="github.com"
GIT_REPO_PORT="22"
GIT_SALT_STATES="ssh://git@$GIT_REPO_HOST:$GIT_REPO_PORT/cert-ee/s4a.git"
GIT_SALT_PILLAR="ssh://git@$GIT_REPO_HOST:$GIT_REPO_PORT/cert-ee/s4a.git"
API_HOST="central.example.com"
API_PORT="5000"
API_URL="http://$API_HOST:$API_PORT/api/report/feedback"
DEB_REPO_HOST="repo.example.com"
DEB_REPO_PORT="80"

EXPECTED_VERSION="16.04"
EXPECTED_OS_ID="ubuntu"

SSH_KEY_PATH="/root/.ssh"
SSH_KEY="$SSH_KEY_PATH/id_rsa"
SSH_KEY_PUB="$SSH_KEY_PATH/id_rsa.pub"

REQUIRED_PKGS="curl pwgen apache2-utils jq git xz-utils python-pygit2 libssh2-1"
SALT_STATES="detector/detector,detector/nginx"

S4A_USER="s4a"
HTPASSWD_PATH="/etc/nginx/.htpasswd"
DEFAULT_USER="admin"

ERRORS_DETECTED=0

DISK_ROOT_AVAIL=10000000
DISK_SRV_AVAIL=10000000
MEM_TOTAL=32000000
CPU_SUGGESTED=4

#export LC_ALL=C
export TEXTDOMAINDIR="./locale"
export TEXTDOMAIN="en"
[[ ${LANG/\.*/} == "et_EE" ]] && export TEXTDOMAIN="et"
# No translation, fallback to EN
[[ ! -d $TEXTDOMAINDIR/$TEXTDOMAIN ]] && export LANG=en_US.UTF-8
# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
col_bold="\e[1m"
col_red="\e[31;1m"
col_rst="\e[0m"

function check_port
{
	local host="$1"
	local port="$2"
	nc -zw3 $host $port && echo "1"
}

function confirm
{
	local msg="$1"
	while true;
	do
		read -p "$msg " yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) exit 1;;
			* ) echo "$( gettext -s yes_or_no )";;
		esac
	done
}

function msg_exit
{
	local msg="$1"
	echo -e "${col_red}$msg${col_rst}"
	exit 1
}

function msg_header
{

	echo -e "${col_bold}$1${col_rst}"
}

# -----------------------------------------------------------------------------
# Checks
# -----------------------------------------------------------------------------
# dpkg availability and version check
#
if [ -e /etc/os-release ] ; then
	. /etc/os-release
else
	PRETTY_NAME=$( getext -s "unknown_os" )
	which dpkg >/dev/null 2>&1
	if [ $? != 0 ] ; then
		msg_exit "$( gettext -s coward_quits )"
	fi
fi

if [ "x$ID" != "x$EXPECTED_OS_ID" ] || [ "x$VERSION_ID" != "x$EXPECTED_VERSION" ] ; then
	echo -e "\n	$( gettext -s software_is_designed_to_run_on ) $EXPECTED_OS_ID $EXPECTED_VERSION"
	echo -e "	$( gettext -s on_your_own_if_running ) $PRETTY_NAME\n"

	confirm "$( gettext -s wish_for_continue )"
fi

# Root permissions are required to run this script
if [ $(whoami) != "root" ]; then
    msg_exit "$( gettext -s need_root )"
fi


# "Disclaimer"
msg_header "\n$( gettext -s install_initiated ):"
echo -e """
	$( gettext -s script_runs_from_url ):
	${col_bold}${SALT_BOOTSTRAP}${col_rst}

	$( gettext -s extra_packages_needed ):
	${col_bold}(${REQUIRED_PKGS// /, })${col_rst}

	$( gettext -s salt_state_will_be_added ):
	${col_bold}${GIT_SALT_STATES}${col_rst} 

	($( gettext -s require_outbond_ssh )) 
	
	$( gettext -s average_execution_time )
"""

msg_header "\n$( gettext -s initial_requirements )\n"

# Some essential tests
if [ -e /etc/default/s4a-detector ] && [ -e /root/.mongodb.passwd ] ; then
	$( confirm "$( gettext -s previous_install_detected )" )
	if [ $? == 0 ] ; then
		. /root/.mongodb.passwd
		/usr/bin/mongo --quiet --authenticationDatabase admin -u $MONGODB_USER -p $MONGODB_PASS s4a-detector --eval "db.dropDatabase();"
	fi
fi

if [ ! $( check_port $DEB_REPO_HOST $DEB_REPO_PORT ) ] ; then
	msg_exit "$( gettext -s host_unreachable ): $DEB_REPO_HOST $( gettext -s port ) $DEB_REPO_PORT"
fi
if [ ! $( check_port $GIT_REPO_HOST $GIT_REPO_PORT ) ] ; then
	msg_exit "$( gettext -s host_unreachable ): $GIT_REPO_HOST $( gettext -s port ) $GIT_REPO_PORT"
fi

if [ ! $( check_port $API_HOST $API_PORT ) ] ; then
	msg_exit "$( gettext -s host_unreachable ): $API_HOST $( gettext -s port ) $API_PORT"
fi

if [ $( df --output=avail / | tail -1 ) -lt $DISK_ROOT_AVAIL ] || [ $( df --output=avail /srv/ | tail -1 ) -lt $DISK_SRV_AVAIL ] ; then
	msg_header "\n$( gettext -s low_on_space )"
	echo ""
	df -hT -x tmpfs -x devtmpfs
fi

if [ $( grep -i ^MemTotal /proc/meminfo  | awk {'print $2'} ) -lt 32000000 ] ; then
	msg_header "\n$( gettext -s low_on_mem )"
	echo ""
	free -h
fi

if [ $( grep -c ^processor /proc/cpuinfo ) -lt $CPU_SUGGESTED ] ; then
	msg_header "\n$( gettext -s zx_spectrum_detected )"
	grep "^\(processor\|model name\)" /proc/cpuinfo
fi

confirm "$( gettext -s wish_to_continue )"

# -----------------------------------------------------------------------------
# Install
# -----------------------------------------------------------------------------
msg_header "* $( gettext -s installing_prequisites ): "
REPO_CHK=`grep -c "https://$DEB_REPO_HOST xenial universe" /etc/apt/sources.list.d/repo-s4a.list 2>/dev/null`
if [ ${REPO_CHK:-0} -lt 1 ] ; then
	echo "deb [arch=amd64 trusted=yes] https://$DEB_REPO_HOST xenial universe" | sudo tee -a /etc/apt/sources.list.d/repo-s4a.list
fi
echo "	$REQUIRED_PKGS"
apt_result=$( apt-get update && apt-get -q -y install $REQUIRED_PKGS 2>&1 )
msg_header "* $(gettext -s bootstrapping_salt):"
echo "	$SALT_BOOTSTRAP"
salt_bootstrap_result=$( curl -s -L $SALT_BOOTSTRAP | LANG=en_US.UTF-8 sh 2>&1 )
if [ $? != 0 ] ; then
	msg_header "$( gettext -s salt_install_failed ): "
	echo -e "---\n$salt_result\n---"
	ERRORS_DETECTED=1
else
	msg_header "* $( gettext -s configure_salt )"
	#
	# go into masterless mode, define "detector environment" and make it for as "top state"
	# https://docs.saltstack.com/en/latest/ref/configuration/master.html#std:conf_master-file_roots
	#
	cat > /etc/salt/minion.d/masterless.conf <<EOF

state_output: terse
retcode_passthrough: true

use_superseded:
  - module.run

file_client: local

gitfs_provider: pygit2
fileserver_backend:
- git
  
gitfs_pubkey: $SSH_KEY_PUB
gitfs_privkey: $SSH_KEY
  
gitfs_remotes:
  - $GIT_SALT_STATES

gitfs_root: saltstack/salt/

ext_pillar:
  - git: 
    - ${GIT_SALT_PILLAR}:
      - root: saltstack/pillar/
      - privkey: $SSH_KEY
      - pubkey: $SSH_KEY_PUB
EOF
	systemctl stop salt-minion >/dev/null 2>&1
	systemctl disable salt-minion  >/dev/null 2>&1

	msg_header "* $( gettext -s configure_ssh_keys )"
	mkdir -p $SSH_KEY_PATH
	cp ssh_keys/detector.id_rsa $SSH_KEY
	cp ssh_keys/detector.id_rsa.pub $SSH_KEY_PUB

	msg_header "* $( gettext -s apply_state )"
	salt_result=$( salt-call -l quiet state.apply $SALT_STATES 2>&1 )
	# Successful initial install?
	if [ $? == 0 ] ; then
		password=$( pwgen 12 1 )
		[[ ! -e $HTPASSWD_PATH ]] && arg_create="-c"
		htpasswd $arg_create -b $HTPASSWD_PATH $DEFAULT_USER $password
		chown $S4A_USER $HTPASSWD_PATH
		chmod a+r $HTPASSWD_PATH

		echo -e "  $( gettext -s system_is_installed )\n"
		for ip in $( ip route | grep src  | cut -d" " -f 12 )
		do
			echo -e "    http://$ip\n"
		done
		msg_header "    $( gettext -s username ): $DEFAULT_USER"
		msg_header "    $( gettext -s password ): $password"
	else
		ERRORS_DETECTED=1
	fi

fi

# -----------------------------------------------------------------------------
# Support request
# -----------------------------------------------------------------------------
if [ "x$ERRORS_DETECTED" != "x0" ] ; then
	msg_header "	$( gettext -s state_failed):"
	echo -e "---\n$apt_result\n---\n$salt_result\n---" | sed "s/^/\t\t/"

	confirm "$( gettext -s send_to_cert )"

	# Prepare variables
	machine_id=$( cat /var/lib/dbus/machine-id )
	apt_result=$( echo "$apt_result" | sed "s/\"/\\\"/g" | sed ':a;N;$!ba;s/\n/\\n/g')
	salt_bootstrap_result=$( echo "$salt_bootstrap_result" | sed "s/\"/\\\"/g" | sed ':a;N;$!ba;s/\n/\\n/g')
	salt_result=$( echo "$salt_result" | sed "s/\"/\\\"/g" | sed ':a;N;$!ba;s/\n/\\n/g')

	# Submit request
	cert_result=$( curl -s $API_URL \
				-XPOST \
				--header 'Accept: application/json' \
				-H "Content-type: application/json" \
				-d '{ "message": "initial installation failed", "id": "'$machine_id'", "logs": { "apt": "'"$apt_result"'", "salt_bootstrap": "'"$salt_bootstrap_result"'", "salt": "'"$salt_result"'"} }' )

	# Output results
	case_nr=$( echo $cert_result | jq -r '.case_number' || submit_error="$cert_result" )
	faq_url=$( echo $cert_result | jq -r '.faq_url' || submit_error="$submit_error\n---\n$cert_result" )
	if [ -z $submit_error ] ; then
		echo -e "\n\t$( gettext -s log_sent_to_cert ):\n\t\tID: $machine_id\n\t\t$( gettext -s received_case_nr ): $case_nr"
		echo -e "\n\t$faq_url\n"
	else
		echo "\n---$submit_error\n---"
	fi
fi

#!/bin/bash
# 
# Set up new Ubuntu 20.04 LTS
# 
#
# *********************************************************************
# *
# * Sean Embry
# * 2021-12-04
# *
# * Revision list here:
# * YYYY-MM-DD-xxx	Notes
# * 2021-12-04-000	Initial buildout 
# * 2021-12-05-000	fixups to .bashrc mods
# * 2021-12-06-000      Add hostname and sshd change ups
# * 2021-12-07-000      Add hostname ctl
# * 2021-12-20-000	Add common tools I use
# * 2021-21-22-000	fix bugs from typos
# *
# *
# *
# *********************************************************************



datenm=`date +%Y%m%d`
# Test for raspberry pi
   if [ -r /sys/firmware/devicetree/base/model ]
        then
            Raspberry=0
	else
	    Raspberry=1
   fi

#####################
##### FUNCTIONS #####
#####################

function check_bash() 

{
grep -q 'BASHMODSWE' ~/.bashrc
nobash=`echo $?`
if [ ${nobash} -eq 1 ]
then
	echo "Making changes for ~/.bashrc!"; read -p "CTRL C to stop"
	cp ~/.bashrc ~/.bashrc.${datenm}
	echo '
HISTSIZE=-1
HISTFILESIZE=-1
BASHMODSWE="true"
# url = git@github.com:sean78253/notes.git
# url = git@github.com:sean78253/fsmod.git
# url = git@github.com:sean78253/oneoffs.git
# url = git@github.com:sean78253/blocklists.git
# or
# https://github.com/sean78253/notes.git
# https://github.com/sean78253/fsmod.git
# https://github.com/sean78253/oneoffs.git
# https://github.com/sean78253/blocklists.git

if [ -z "$SSH_AUTH_SOCK" ] ; then
	eval `ssh-agent -s`
	ssh_keys=`find ~/.ssh/id_rsa* | grep -v '\.pub' | xargs` && ssh-add -q ${ssh_keys}
	unset ssh_keys
fi

function cleanup()
{
	test -n "$SSH_AGENT_PID" && eval `/usr/bin/ssh-agent -k`
	echo RELOADAGENT | gpg-connect-agent
}

trap cleanup EXIT
' >> ~/.bashrc
else
	echo "Skipping bash fixup, it is done"
fi
}

function check_host()
{
	curhost=`hostname`
	hnc=`which hostnamectl`
	if [ ${curhost} = 'localhost' ]
		then
			read -p "New host name: " newhost
			read -p "New host is ${newhost} (ctrl C to abort): " trash
			hostname $newhost
			cp /etc/hosts /etc/hosts.${datenm}
			sed "s/localhost/$newhost/" /etc/hosts.${datenm} > /etc/hosts 

				if [ ! -z ${hnc} ]
					then
						echo "${hnc} detected: Calling it as well"
						hostnamectl set-hostname ${newhost}
				fi
		else
			echo "Skipping hostname, it is not localhost"
	fi
}

function move_ssh()
{
	# do we even have sshd installed?
	if [ -f /etc/ssh/sshd_config ]
		then
			# if we do does it have a Port defined if so abort
			grep -q "^Port" /etc/ssh/sshd_config
			porter=`echo $?`
			if [ ${porter} -eq 1 ]
				then
					echo "Doing sshd mods"
					cp /etc/ssh/sshd_config /etc/ssh/sshd_config.${datenm}
					echo "Port 4822" >> /etc/ssh/sshd_config
					systemctl reload sshd
				else
					echo "Skipping ssh changes, /etc/ssh/sshd_config has a defined port"
			fi
		else
			echo "sshd does not have a config file - is it installed?"
	fi
}

function is-a-pi()
{

   if [ -r /sys/firmware/devicetree/base/model ]
	then
	    ISPI=0
   fi

}

function pi-wired()
{

# for wireless being used for internet, wired for private netowrk. No packet forwarding. That is another step.

#steps:
#check we are a pi
#check wired interface has nothing allocated
#check wired interface is disconnected?
if [ ${isapi} -eq 1 ]
then
	echo "
interface eth0
static ip_address=192.168.1.1
#static ip6_address=fd51:42f8:caae:d92e::ff/64
static routers=192.168.1.1/24
nogateway
denyinterfaces wlan0
denyinterfaces wlan1
"
else
	echo "This is not a raspbery Pi system"
fi


}

function grab_ssh_keys()
{
true
# create a temp dir to hold keys
# Prompt for URL to grab from, check for .gpg extention.
# grab 
# 

}


fuction install_tools()

{

sudo apt install pwgen net-tools htop iptables-persistent lynx xtables-addons-common debconf-utils

}

function whichdistro()
{
	# https://www.tecmint.com/find-linux-kernel-version-distribution-name-version-number/
cat /etc/redhat-release
cat /etc/centos-release
cat /etc/fedora-release
cat /etc/debian_version
# ---------- On Ubuntu and Linux Mint ----------
cat /etc/lsb-release
cat /etc/gentoo-release
cat /etc/SuSE-release
}
################
##### WORK #####
################

check_bash
check_host
move_ssh
install_tools

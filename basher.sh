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
# * 2025-05-11-000	Add choice to install all partition types
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
export HISTSIZE=-1
export HISTFILESIZE=-1
# uncommnet if gcp fiernts export DISPLAY=:0.0
export EDITOR=/usr/bin/vi
export BASHMODSWE="true"
# url = git@github.com:sean78253/notes.git
# url = git@github.com:sean78253/fsmod.git
# url = git@github.com:sean78253/oneoffs.git
# url = git@github.com:sean78253/blocklists.git
# or
# https://github.com/sean78253/notes.git
# https://github.com/sean78253/fsmod.git
# https://github.com/sean78253/oneoffs.git
# https://github.com/sean78253/blocklists.git
# sshfs -p 4822 root@unfoxthecablebox.com:/root /home/sean/rmtmnt
# VLC addons
# apt install -y vlc-plugin-bittorrent vlc-plugin-fluidsynth vlc-plugin-jack vlc-plugin-notify vlc-plugin-qt vlc-plugin-samba vlc-plugin-skins2 vlc-plugin-svg vlc-plugin-video-output vlc-plugin-video-splitter vlc-plugin-visualization vlc-plugin-vlsub
# more video
# sudo sh -c 'echo "deb https://mkvtoolnix.download/ubuntu/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/bunkus.org.list'
# wget -q -O - https://mkvtoolnix.download/gpg-pub-moritzbunkus.txt | sudo apt-key add -
# sudo apt-get update
# sudo apt-get install mkvtoolnix mkvtoolnix-gui

# apache2 apt-transport-https certbot cmake cpuid curl debconf-utils dmraid dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-pop3d exfatprogs freerdp2-dev git gnupg2 gpart gparted gpg htop iptables-persistent jfsutils jq kpartx libapache2-mod-php libavcodec-dev libavformat-dev libavutil-dev libcairo2-dev libjpeg-turbo8-dev libossp-uuid-dev libpango1.0-dev libpng-dev libpulse-dev libssh2-1-dev libssl-dev libswscale-dev libtelnet-dev libtool-bin libvncserver-dev libvorbis-dev libwebp-dev libwebsockets-dev lynx make mtools mysql-server ncdu net-tools openjdk-11-jdk openssh-server php-curl php-mbstring php-mysql php-xml postfix postfix-mysql pwgen python3 python3-pip reiser4progs reiserfsprogs samba software-properties-common sshfs tomcat9 tomcat9-admin tomcat9-common tomcat9-docs tomcat9-examples tomcat9-user udftools uuid-dev vim vlc vlc-plugin-bittorrent vlc-plugin-fluidsynth vlc-plugin-jack vlc-plugin-notify vlc-plugin-qt vlc-plugin-samba vlc-plugin-skins2 vlc-plugin-svg vlc-plugin-video-output vlc-plugin-video-splitter vlc-plugin-visualization wget xfsprogs

if [ -z "$SSH_AUTH_SOCK" ] ; then
	eval `ssh-agent -s`
	ssh_keys=`find ~/.ssh/id_rsa* | grep -v '\.pub' | xargs` && ssh-add -q ${ssh_keys}
	unset ssh_keys
fi

repos="oneoffs works fsmon"

echo -e "\n"

for i in $repos
do
        if [ -d ~/repos/$i ]
        then
        	git -C ~/repos/$i fetch
                stat=`git -C ~/repos/$i status | grep 'Your branch'`
                echo "***** $i *****"
                echo $stat
                echo "git -C ~/repos/$i pull"
        else
                echo "***** WARNING *****"
                echo "$i - repository not present in ~/repos"
        fi
done


function cleanup()
{
	test -n "$SSH_AGENT_PID" && eval `/usr/bin/ssh-agent -k`
	echo RELOADAGENT | gpg-connect-agent
}

trap cleanup EXIT
' >> ~/.bashrc
echo "Host mygeekisp.com
	Port 4822
	StrictHostKeyChecking no

Host *.mygeekisp.com
	Port 4822
	StrictHostKeyChecking no

Host seanembry.com
	Port 4822
	StrictHostKeyChecking no

Host unfoxthecablebox.com
	Port 4822
	StrictHostKeyChecking no

Host vixenfakenews.com
	Port 4822
	StrictHostKeyChecking no

host 10.0.0.0/8
	StrictHostKeyChecking no

host 192.168.0.0/16
	StrictHostKeyChecking no

host 172.17.0.1
	IdentitiesOnly yes

host 172.16.0.0/12
	StrictHostKeyChecking no
" > ~/.ssh/config

journalctl --vacuum-time=10d

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

function move_new_ssh()
{
	true
# https://askubuntu.com/questions/1533119/ssh-connection-refused
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


function install_tools()

{

sudo apt -d update
sudo apt install -y pwgen net-tools htop iptables-persistent lynx debconf-utils cpuid curl gpg ncdu sshfs gparted dmraid gpart jfsutils kpartx mtools reiser4progs reiserfsprogs udftools xfsprogs exfatprogs vim gcp sysstat traceroute
sudo apt upgrade -y

# For typcial desk top or personal servers
# sudo apt install libcdio-utils
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

function gitconfig()
{
if [ ! -f ~/.gitconfig ]
then
echo "[user]
# Please adapt and uncomment the following lines:
	name = sean78253
	email = sean_e6@yahoo.com
" > ~/.gitconfig
fi
}

function locali()
{
echo "# BASHER ALIASES
alias fmnt='findmnt -D -t nosquashfs,notmpfs,nodevtmpfs,notracefs'
" >> ~/.bash_aliases
mkdir ~/repos && cd ~/repos && git clone git@github.com:sean78253/oneoffs.git && git clone git@github.com:sean78253/works.git
scp -P 4822 root@mygeekisp.com:/root/.ssh/id_rsa* /root/.ssh/
# if [ ! -d /guac ]
# then
	# mkdir /guac
# fi
# scp -P 4822 root@mygeekisp.com:/guac/* /guac/
}


# add drive support

function add_drive_support()
{
apt install cryptsetup dmsetup exfat-fuse exfat-utils f2fs-tools gdisk gparted hfsprogs hfsutils jfsutils lvm2 nilfs-tools reiser4progs reiserfsprogs sysstat udftools util-linux xfsdump xfsprogs

# Edit /etc/modules, add exfat to list if not present

grep -s exfat /etc/modules; EX_FAT=$?

if [ ${EX_FAT} -eq 1 ]
then
	echo "exfat" >> /etc/modules
fi
}

# add_drive_support


################
##### WORK #####
################

check_bash
check_host
move_ssh
gitconfig
install_tools
# add_drive_support
locali

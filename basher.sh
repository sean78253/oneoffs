datenm=`date +%Y%m%d`
##### FUNCTIONS

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

if [ -z "$SSH_AUTH_SOCK" ] ; then
	eval `ssh-agent -s`
	ssh_keys=`find ~/.ssh/id_rsa* | grep -v '\.pub' | xargs` && ssh-add -q $ssh_keys
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
	echo "Skipping bash fixup, it's done"
fi
}

function check_host()
{
	curhost=`hostname`
	if [ ${curhost} = 'localhost' ]
		then
			read -p "New host name: " newhost
			read -p "New host is ${newhost} (ctrl C to abort): " trash
			hostname $newhost
			cp /etc/hosts /etc/hosts.${datenm}
			sed "s/localhost/$newhost/" /etc/hosts.${datenm} > /etc/hosts 
		else
			echo "Skipping hostname, it is not localhost"
	fi
}

function move_ssh()

{
		grep -q "^Port" /etc/ssh/sshd_config
		porter=`echo $?`
		if [ ! ${porter} ]
			then
				echo "Doing sshd mods"
				cp /etc/ssh/sshd_config /etc/ssh/sshd_config.${datenm}
				echo "Port 4822" >> /etc/ssh/sshd_config
				systemctl reload sshd
			else
				echo "Skipping ssh changes, done"
		fi
}


###### WORK
check_bash
check_host
move_ssh

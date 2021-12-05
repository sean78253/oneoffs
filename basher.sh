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
'

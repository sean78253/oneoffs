#!/bin/bash
# 
#
#
# *********************************************************************
# *
# * Sean Embry
# *
# * Revision list here:
# * YYYY-MM-DD-xxx	Work scope Notes
# * YYYY-MM-DD-xxx	HOURS: INITALS 1.25 for an hour and 15 minutes
# *			Notes
# *
# * 2022-01-12-000	inital build out
# * 2022-01-12-000	HOURS: SWE 2.75
# *
# * 2022-01-14-000	Bug hunting for mailuser
# * 2022-01-14-000	HOURS: SWE 1.5
# *			Turns out we need to use "localhost" instead of "127.0.0.1" DERP!
# *
# * 2022-01-15-000	Corrected to use UTF8MB4 instead of utf8 as utf8 is being depricated	
# * 2022-01-15-000	HOURS: SWE 1.0
# *			Also gets rid of annoying warnings while createing the table.
# *			Added a quota field for users for possible future use. 0 = unlimited
# *
# * 2022-01-15-001	Start with adding a control table for virtual domains and users for imports
# * 2022-01-15-001	HOURS: SWE 1.50
# 
# * 2022-01-16-000	Add mailadmin accout - add to mkmail.sh
# * 2022-01-16-000	HOURS: SWE 0.25
# *
# * 2022-01-20-000	clean up, change not allowed for pwgen, change some table logic
# * 2022-01-20-000	HOURS: SWE 3.0
# *
# * 2022-01-21-000	Add debconf purge logic
# *
# *
# *
# *
# *
# *
# *
# *
# *
# *
# *
# *
# *
# *
# *
# *
# *********************************************************************
# NOTES:
# Think more on quota and how we describe it. Better for 1024 for 1K or just 1K, 1M, 1G exctera
# Thank about limiting mailuser to mailserver.virtual_domain, .virtual_user, and .virtual_aliases
#
#
#
# *********************************************************************
# TODOS
#
#
#
#
#
# *******************
# * DEFINE VARABLES *
# *******************
_dte=`date +%s`

# _PWLIMIT are charecters we will not permit pwgen to use in the SQL mailserver.virtual_user database does not apply to mysql.user at this time
# _PWLIMIT=\@\?\^\&\:\~\?\;\:\[\]\{\}\.\,
_PWLIMIT=\@\?\&\:\?\;\:\[\]\{\}\.\,\'\%\"\*\(\)\\\/

# the mailadmin user has full rights to mailserver.* tables
mailadminpassword=`cat ~/mkmail2.pass | grep 'mailadmin' | awk '{print $3}'`
# the mailuser has only select rights on mailserver.* and I may make it only on virtual_user, virtual_aliases and virtual_domain tables
mailuserpassword=`cat ~/mkmail2.pass | grep 'mailuser' | awk '{print $3}'`

# **********************
# * RESOLVE VAR ISSUES *
# **********************


# *************
# * FUNCTIONS *
# *************

function create_database()
{
echo "
CREATE DATABASE IF NOT EXISTS mailserver;
CREATE USER 'mailuser'@'localhost' IDENTIFIED BY '${mailuserpassword}';
GRANT SELECT ON mailserver.* TO 'mailuser'@'localhost';
CREATE USER 'mailadmin'@'localhost' IDENTIFIED BY '${mailadminpassword}';
GRANT ALL ON mailserver.* TO 'mailadmin'@'localhost';
FLUSH PRIVILEGES;
USE mailserver;
CREATE TABLE IF NOT EXISTS \`virtual_domains\` ( \`id\` int NOT NULL auto_increment, \`name\` varchar(50) NOT NULL, PRIMARY KEY (\`id\`)) ENGINE=InnoDB DEFAULT CHARSET=UTF8MB4;
CREATE TABLE IF NOT EXISTS \`virtual_users\` ( \`id\` int NOT NULL auto_increment, \`domain_id\` int NOT NULL, \`password\` varchar(106) NOT NULL, \`email\` varchar(100) NOT NULL, \`quota\` int NOT NULL DEFAULT 0, PRIMARY KEY (\`id\`), UNIQUE KEY \`email\` (\`email\`), FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=UTF8MB4;
CREATE TABLE IF NOT EXISTS \`virtual_aliases\` ( \`id\` int NOT NULL auto_increment, \`domain_id\` int NOT NULL, \`source\` varchar(100) NOT NULL, \`destination\` varchar(100) NOT NULL, PRIMARY KEY (\`id\`), FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=UTF8MB4;
" > ~/make_email.sql
}

function populate_domains()
{
 	while read domain id
 	do
		if [ -z ${id} ]
	       	then
 		echo "INSERT INTO mailserver.virtual_domains (name) VALUES ('${domain}');"
		fi
 	done < ~/maildomains >> ~/make_email.sql
# select domains with no accounts: should be no admin accounts
# select name from virtual_domains where id not in (select domain_id from virtual_users);

}

function populate_users()
{
while read acct quota apass
do
	edomain=`echo $acct | sed 's/@/ /' | awk '{print $2}'`
	if [ -z ${quota} ]
	then
		quota=0
	fi
	if [ -z ${apass} ]
	then
		apass=`pwgen -syr ${_PWLIMIT} 10 1`
	fi
echo "insert into mailserver.virtual_users (domain_id, password, email, quota) values ((select id from virtual_domains where name = '${edomain}'), TO_BASE64(UNHEX(SHA2('${apass}', 512))), '${acct}', ${quota});"
	quota='' apass=''
done < ~/mailaccounts >> ~/make_email.sql
}

function rfcaccounts()
{
echo "Setting up RFC suggested accounts with random passwords. If you define one in the user file, that password will be assigned."

while read domain 
do
# admdomainpass=`pwgen -r ${_PWLIMIT} -y -s 10 1`
admdomainpass=`pwgen 10 1`
echo "
INSERT ignore into mailserver.virtual_users (domain_id, password, email) values ((select id from virtual_domains where name = '${domain}'), TO_BASE64(UNHEX(SHA2('${admdomainpass}', 512))), 'admin@${domain}');
INSERT ignore INTO mailserver.virtual_aliases (domain_id, source, destination) VALUES ((select id from virtual_domains where name = '${domain}'), 'abuse@${domain}', 'admin@${domain}'); 
INSERT ignore INTO mailserver.virtual_aliases (domain_id, source, destination) VALUES ((select id from virtual_domains where name = '${domain}'), 'postmaster@${domain}', 'admin@${domain}'); 
INSERT ignore INTO mailserver.virtual_aliases (domain_id, source, destination) VALUES ((select id from virtual_domains where name = '${domain}'), 'hostmaster@${domain}', 'admin@${domain}');
INSERT ignore INTO mailserver.virtual_aliases (domain_id, source, destination) VALUES ((select id from virtual_domains where name = '${domain}'), 'webmaster@${domain}', 'admin@${domain}');
" >> ~/make_email.sql
done < ~/maildomains 
}

function cleandevconf()
{
echo PURGE | debconf-communicate mysql-server
echo PURGE | debconf-communicate postfix
}

function crdc()
{
	# Create directories for virtual domains using dovecot
havegrp=`grep vmail /etc/group`
haveusr=`grep vmail /etc/passwd`
if [ -z ${havegrp} ]
then
	echo "Needs group"
	groupadd -g 5000 vmail
fi

if [ -z ${haveusr} ]
then
	echo "Needs user"
	useradd -g vmail -u 5000 vmail -d /var/mail --shell /usr/bin/false
fi

while read domain
do
	mkdir -p /var/mail/vhosts/${domain}
done < ~/maildomains
chown -R vmail:vmail /var/mail
}


# ****************
# * BODY OF WORK *
# ****************

create_database
populate_domains
rfcaccounts
populate_users
crdc
cleandevconf

echo "Now log into mysql with your root password and run source ~/make_email.sql
Remember to delete ~/make_emai.sql and the ~/mkemail.pass file as they have passwords in them."
exit 0

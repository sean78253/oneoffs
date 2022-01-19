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
# * 2022-01-16-000	Add mailadmin accout - add to mkmail2.sh
# * 2022-01-16-000	HOURS: SWE 0.25
# *
# *
# *********************************************************************
# NOTES:
# Think more on quota and how we describe it. Better for 1024 for 1K or just 1K, 1M, 1G exctera
#
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
mailadminpassword=`cat ~/mkmail2.pass | grep 'mailadmin' | awk '{print $3}'`
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
" > /tmp/swe
}

function populate_domains()
{
 	while read domain id
 	do
		if [ -z ${id} ]
	       	then
 		echo "INSERT INTO mailserver.virtual_domains (name) VALUES ('${domain}');"
		fi
 	done < ~/maildomains >> /tmp/swe
# select domains with no accounts: should be no admin accounts
# select name from virtual_domains where id not in (select domain_id from virtual_users);

}

function populate_users()
{
	true
while read acct quota apass
do
	edomain=`echo $acct | sed 's/@/ /' | awk '{print $2}'`
	if [ -z ${quota} ]
	then
		quota=0
	fi
	if [ -z ${apass} ]
	then
		apass=`pwgen 10 1`
	fi
echo "insert into mailserver.virtual_users (domain_id, password, email, quota) values ((select id from virtual_domains where name = '${edomain}'), TO_BASE64(UNHEX(SHA2('${apass}', 512))), '${acct}', ${quota});"
	quota='' apass=''
done < ~/mailaccounts >> /tmp/swe
echo -e "\n\n**********"
echo "* NOTE!! *"
echo "**********"
echo -e "\nIf you have not yet created an admin@(domainname_here) you should. Here's the SQL for that:\n"

}

function rfcaccounts()
{
# while read a b; do echo $a | sed 's/@/ /'; done < mailaccounts | awk '{print $2}' | sort | uniq | xargs
# clear
echo "I can set up your RFC required accounts if you like. Enter the password for the administrative email accout"
echo -e "Do not worry - if it is already there, it won't change a thing.\n"
admdomain=`while read admaccount trash; do echo ${admaccount} | sed 's/@/ /'; done < ~/mailaccounts | awk '{print $2}' | sort | uniq | xargs`

for admact in ${admdomain}
do
read -p "       Please input a password for the admin@${admdomain}:" admdomainpass

echo "
insert ignore into mailserver.virtual_users (domain_id, password, email) values ((select id from virtual_domains where name = '${admact}'), TO_BASE64(UNHEX(SHA2('${admdomainpass}', 512))), 'admin@${admact}');
INSERT ignore INTO mailserver.virtual_aliases (domain_id, source, destination) VALUES ((select id from virtual_domains where name = '${admact}'), 'abuse@${admact}', 'admin@${admact}');
INSERT ignore INTO mailserver.virtual_aliases (domain_id, source, destination) VALUES ((select id from virtual_domains where name = '${admact}'), 'postmaster@${admact}', 'admin@${admact}');
INSERT ignore INTO mailserver.virtual_aliases (domain_id, source, destination) VALUES ((select id from virtual_domains where name = '${admact}'), 'hostmaster@${admact}', 'admin@${admact}');
INSERT ignore INTO mailserver.virtual_aliases (domain_id, source, destination) VALUES ((select id from virtual_domains where name = '${admact}'), 'webmaster@${admact}', 'admin@${admact}');
" >> /tmp/swe
done

}

function populate_alias()
{
	true
#	abuse@ webmaster@ hostmaster@ postmaster@
# insert into mailserver.virtual_aliases (domain_id, source, destination) VALUES ('1', 'alias@example.com', 'user@example.com');
}

# ****************
# * BODY OF WORK *
# ****************

create_database
populate_domains
populate_users
rfcaccounts

exit 0

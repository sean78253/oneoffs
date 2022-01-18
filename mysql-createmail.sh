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
"
}

function populate_domains()
{
	echo "mysql -u mailadmin -p${mailadmin}"
 	while read domain id
 	do
		if [ -z ${id} ]
	       	then
 		echo "INSERT INTO mailserver.virtual_domains (name) VALUES ('${domain}');"
		fi
 	done < ~/maildomains
}

function populate_users()
{
	true
# insert into virtual_users (domain_id, password, email) values ((select id from virtual_domains where name = 'atcsrailfan.com'), TO_BASE64(UNHEX(SHA2('password', 512))), 'pooh@usersunion.com');
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


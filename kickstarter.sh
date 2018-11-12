#!/bin/bash

##################################################
# Setup postgres and prepare a Jira dbconfig.xml #
##################################################

DBDUMP=$1

# Get the username to peg
#
DB_USERNAME=$(curl -s $DBDUMP | head -10000 | awk '/ALTER TABLE/ && /OWNER/ { print $NF }' | sort | uniq | tr -d ';')

# get the JDBC URL
#
DB_NAME=$(curl -s $DBDUMP | head -10000 | awk '/CREATE SCHEMA/ && !/public/ { print $NF }' | tr -d ';')


# Get postgres rolling
#
su -c "/opt/rh/rh-postgresql10/root/usr/bin/postgres -D /opt/postgres10 -c config_file=/opt/postgres10/postgresql.conf &" postgres;

sleep 5


# Create a postgres user
#
su -c "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/createuser -s $DB_USERNAME" postgres

# Passwordize said postgres user
#
su -c "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql -c \"alter user $DB_USERNAME password 'jira';\"" postgres

# Create a postgres database
#
su -c "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/createdb $DB_NAME --owner $DB_USERNAME" postgres

# GRANT ALL (Maybe superfluous)
#
su -c "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql -c \"GRANT ALL PRIVILEGES ON DATABASE $DB_NAME to $DB_USERNAME;\"" postgres


# Load dump to DB
#
curl -s $DBDUMP | LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql -U $DB_USERNAME $DB_NAME

# Disable all directories except the base, local directory
#
su -c "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql  -U $DB_USERNAME $DB_NAME -c \"update cwd_directory  set active = 0 where id != 1;\"" postgres


# Reset passwords for all members of 'jira-administrators' group
#
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql -U $DB_USERNAME $DB_NAME -t -c "select child_name from cwd_membership where parent_name='jira-administrators' AND directory_id = 1;" | grep -v "^$" | while read localadmin;
do
        echo $localadmin;
        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql -U $DB_USERNAME $DB_NAME -t -c "update cwd_user set credential='{PKCS5S2}b3c19ePbQB4BAWzb6NogB7oTuSKOATvJxT1JP/1knh+fi1ZwJ8TGmnzmssJsBYvG' where user_name='"$localadmin"';"
        export $localadmin
done


#####################

# What version of Jira was this backed-up from?
JIRA_VERSION=$(LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql -t -U postgres jiraprdb1 -c "select propertyvalue from propertystring where id = (select id from propertyentry where property_key = 'jira.version');" | tr -d ' ')

cd /opt

echo "Build /opt/atlassian-jira-software-$JIRA_VERSION.tar.gz"

tar -zxvf /opt/atlassian-jira-software-$JIRA_VERSION.tar.gz

echo "jira.home = /opt/jirahome" >  /opt/atlassian-jira-software-$JIRA_VERSION-standalone/atlassian-jira/WEB-INF/classes/jira-application.properties


# Assemble Jira's dbconfig.xml
#

cat<<EOF > /opt/jirahome/dbconfig.xml
<?xml version="1.0" encoding="UTF-8"?>
<jira-database-config>
  <name>defaultDS</name>
  <delegator-name>default</delegator-name>
  <database-type>postgres72</database-type>
  <schema-name>public</schema-name>
  <jdbc-datasource>
    <url>jdbc:postgresql://localhost:5432/$DB_NAME</url>
    <driver-class>org.postgresql.Driver</driver-class>
    <username>$DB_USERNAME</username>
    <password>jira</password>
    <pool-min-size>100</pool-min-size>
    <pool-max-size>100</pool-max-size>
    <pool-max-wait>30000</pool-max-wait>
    <pool-max-idle>100</pool-max-idle>
    <pool-remove-abandoned>true</pool-remove-abandoned>
    <pool-remove-abandoned-timeout>300</pool-remove-abandoned-timeout>
    <validation-query>select 1</validation-query>
    <min-evictable-idle-time-millis>60000</min-evictable-idle-time-millis>
    <time-between-eviction-runs-millis>300000</time-between-eviction-runs-millis>
    <pool-test-on-borrow>false</pool-test-on-borrow>
    <pool-test-while-idle>true</pool-test-while-idle>
  </jdbc-datasource>
</jira-database-config>
EOF


# Start Jira in background
#

/opt/atlassian-jira-software-$JIRA_VERSION-standalone/bin/start-jira.sh


# After a 5 minute stand-off cycle through all local admins trying to create user "poppet"
#

sleep 300

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql -U $DB_USERNAME $DB_NAME -t -c "select child_name from cwd_membership where parent_name='jira-administrators' AND directory_id = 1;" | grep -v "^$" | while read localadmin;
do
        echo $localadmin;
        http_proxy="" curl -v -u $localadmin:JiraPassword -H "Content-Type: application/json" -X POST -d '{ "name":"poppet","password":"poppet", "displayName":"least-privilege user", "emailAddress":"none@localhost" }' http://localhost:8080/rest/api/2/user
done



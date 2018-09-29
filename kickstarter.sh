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


# Lock and load
#
curl -s $DBDUMP | LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql -U $DB_USERNAME $DB_NAME

su -c "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64 /opt/rh/rh-postgresql10/root/usr/bin/psql  -U $DB_USERNAME $DB_NAME -c \"update cwd_directory  set active = 0 where id != 1;\"" postgres


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

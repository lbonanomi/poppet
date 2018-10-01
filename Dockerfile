FROM store/oracle/serverjre:8

ENV     HTTP_PROXY      "http://$PROXY_URL"
ENV     HTTPS_PROXY     "http://$PROXY_URL"

# Postgres
#

# Freeze Postgres at the production version and explicitly use those RPMs
#

RUN     mkdir  /opt/rpm

COPY    rh-postgresql10-3.1-1.el7.x86_64.rpm                            /opt/rpm/
COPY    rh-postgresql10-postgresql-10.5-1.el7.x86_64.rpm                /opt/rpm/
COPY    rh-postgresql10-postgresql-libs-10.5-1.el7.x86_64.rpm           /opt/rpm/
COPY    rh-postgresql10-postgresql-server-10.5-1.el7.x86_64.rpm         /opt/rpm/
COPY    rh-postgresql10-runtime-3.1-1.el7.x86_64.rpm                    /opt/rpm/
COPY    rh-postgresql96-postgresql-server-9.6.10-1.el7.x86_64.rpm       /opt/rpm/

# Let yum handle everything else
#

RUN     yum install libselinux-utils policycoreutils-python scl-utils -y

RUN     cd /opt/rpm && rpm -i rh-postgresql10-runtime-3.1-1.el7.x86_64.rpm
RUN     cd /opt/rpm && rpm -i rh-postgresql10-postgresql-libs-10.5-1.el7.x86_64.rpm
RUN     cd /opt/rpm && rpm -i rh-postgresql10-postgresql-10.5-1.el7.x86_64.rpm
RUN     cd /opt/rpm && rpm -i rh-postgresql10-postgresql-server-10.5-1.el7.x86_64.rpm
RUN     cd /opt/rpm && rpm -i rh-postgresql10-3.1-1.el7.x86_64.rpm

RUN     rm -rf /opt/postgres10
RUN     mkdir /opt/postgres10
RUN     chown postgres /opt/postgres10


USER postgres

RUN     LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-postgresql10/root/usr/lib64  /opt/rh/rh-postgresql10/root/usr/bin/initdb -D /opt/postgres10
ADD     postgresql.conf /opt/postgres10
ADD     pg_hba.conf /opt/postgres10

EXPOSE  5432


# Jira
#

USER root

COPY ./atlassian-jira-software-7.4.4.tar.gz /opt
COPY ./kickstarter.sh /root

WORKDIR /opt

# Unpack a JIRA appliance
#
RUN tar -zxvf atlassian-jira-software-7.4.4.tar.gz
RUN rm /opt/atlassian-jira-software-7.4.4.tar.gz

# Get $jirahome setup
#

RUN mkdir /opt/jirahome
RUN echo "jira.home = /opt/jirahome" >  /opt/atlassian-jira-software-7.4.4-standalone/atlassian-jira/WEB-INF/classes/jira-application.properties

EXPOSE 8080/tcp

CMD [ "bash" ]

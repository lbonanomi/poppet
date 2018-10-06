# poppet

## What's this?

poppet is a docker appliance for Jira users to recover deleted/altered projects and issues.

An infuriatingly frequent task for Jira admins at $EMPLOYER involved recovering deleted projects and issues from SQL dumps on-demand. To smooth this process, poppet drags all of the requisite (Postgres and Jira) goodies into an appliance and provides a script to kickstart a Jira instance from an HTTP-accessible postgres dump.

## How do I run this?

1. Build a docker container with the supplied dockerfile
2. Push said dockerfile to your internal hub
3. Wait patiently for an agitated support request
4. Pull a poppet container and start it as  
   ```docker run -dit -p 8080:8080/tcp --name poppet poppet /root/kickstarter.sh http://postgres_dump_url```
5. Log-in with a local Jira user


## Known Issues

$EMPLOYER uses an Active Directory bridge, please be wary of non local user logins.

The postgres configurations here are hideously insecure.

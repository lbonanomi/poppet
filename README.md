# poppet

> Instant results! Just add water!  
> ~Many Looney Tunes ACME products  


## What's this?

poppet is a docker appliance for rehydrating Jira database dumps.

An infuriatingly frequent task for Jira admins at $EMPLOYER involved recovering deleted projects and issues from SQL dumps on-demand. To smooth-out this process poppet drags all of the requisite (Postgres and Jira) goodies into an appliance and provides a script to kickstart a Jira instance from an HTTP-accessible postgres dump.

## How do I run this?

1. Gather requisite RPMs for building a Postgres instance that matches your production version. 
2. Build a docker container with the supplied dockerfile
3. Push said dockerfile to your internal hub if you have one.
4. Wait patiently for an agitated support request
5. Pull a poppet container and start it as  
   ```docker run -dit -p 8080:8080/tcp --name poppet poppet /root/kickstarter.sh http://postgres_dump_url```
6. Log-in with a local (non-admin) Jira user, or newly created local user "poppet"


## Known Issues

* There is a race condition in creating local user 'poppet'.

* All local admins will have their passwords reset as part of the process.

* The postgres configurations here are hideously insecure.

<!-- Yep, i'm collecting your IP address. -->
<img src="https://evening-spire-71333.herokuapp.com/">

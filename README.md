<center>
  <h1 align=center>Coming Soon</h1>
<center>

# poppet

## What's this?

poppet is a docker appliance for Jira users to recover deleted/altered projects and issues.

An infuriatingly frequent task for Jira admins at $EMPLOYER involved recovering deleted projects and issues from SQL dumps on-demand. To smooth this process, poppet drags all of the requisite (Postgres and Jira) goodies into an appliance and provides a script to kickstart a Jira instance from an HTTP-accessible postgres dump.

## How do I run this?

1. Build a docker container with the supplied dockerfile
2. Push said dockerfile to your internal hub

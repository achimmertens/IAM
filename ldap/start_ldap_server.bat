# podman run -d -p 3389:3389 -p 3636:3636 -e DS_DM_PASSWORD=1234 --name ldap_server 389ds/dirsrv:latest
podman start -a ldap_server

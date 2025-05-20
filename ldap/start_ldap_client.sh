podman exec -it ldap_server bin/bash

// root@3b36b9c40627:/etc# apt update && apt install -y ldap-utils
// ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "dc=example,dc=com"
# Start the LDAP server with network configuration

# podman run --network midpoint_net \
#  -p 3389:3389 -p 3636:3636 \
#  --name ldap_server \
#  -e DS_DM_PASSWORD=1234 \
#  -e DS_SUFFIX_NAME="dc=example,dc=com" \
#  -v ldap_data:/data \
#  389ds/dirsrv

podman start -a ldap_server
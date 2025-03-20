ldapmodify -x -H ldap://localhost:3389 \
  -D "cn=Directory Manager" \
  -w 1234 \
  -f update_johny_depp.ldif
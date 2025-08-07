Mit Strg+Shift+p den Befehl "Run Tasks" eingeben und dann "Start All Services" anklicken. Als Ergebnis öffnen sich mehrere Shell Konsolen in denen die Server gestartet werden:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t7AyRxj3RBvn8btYpGevMbQBpmcK3xdpgMezRW2sVjM8PxsA9zFSdLESxwEFoBmby7n.png)
*Entnommen aus Midpoint-LDAP-Connection.md*

- Zugriff auf NGinx: http://localhost:8080/
- Zugrif auf Keycloak: http://localhost:8081/
- Zugriff auf Midpoint: http://localhost:8082
- Zugriff auf LDAP: 
   - Öffnen der LDAP Shell
   - ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "dc=example,dc=com"

IP-Adressen überprüfen:
podman inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(podman ps -q)

Im Keycloak muss die Verbindung zum LDAPserver angepasst werden. Schaue dazu in die Datei "keycloak.env" und trage die IP Adresse in das LDAP-Federation Feld ein.
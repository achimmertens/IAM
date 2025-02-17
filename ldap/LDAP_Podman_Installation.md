Ich möchte einen LDAP DS 389 Server in einem Container starten und dort meinen ersten User anlegen.
Ich hatte bisher noch so gut wie keine Erfahrung mit LDAP und daher ist dieses Dokument auch an Anfänger gerichtet. Es hat ein paar Tage gedauert, bis ich mit Hilfe von KI und mI (meiner Ingelligenz ;-) einen laufenden Server mit einem User anlegen konnte. 
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/2432cov4FobdPkMegquTgX5LHmBazCFhhs7dEh3a4Zjpxj97Gyb4Ys9RitRmhQaaisUkQ.png)
Folgendes habe ich gemacht:

# LDAP Server runter laden und starten
Ich verwende aus Gründen den LDAP Server DS 389 der auf einem RedHat Linux basiert.
Das dazugehörige Docker/Podman Image kann wie folgt heruntergeladen und zum Starten gebracht werden.

> podman run -d -p 3389:3389 -p 3636:3636 -e DS_DM_PASSWORD=1234 --name ldap_server 389ds/dirsrv:latest

Die LDAP-Tools sind in dem Image ebenfalls vorhanden. Daher ist es sinnvoll sich auf dieses Linux einzuloggen:
> podman exec -it ldap_server bin/bash

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tkjqU46MFEMzyJ42MoJp4ygKFjpC14KMHpJxQBs7XnFgujj64mKyM88VpFxh4JjntP5.png)

Alternativ kann auch der DS-386 von Suse verwendet und mit gewünschten Parameter gestartet werden:

podman run -d \
  -p 3389:3389 \
  -p 3636:3636 \
  -e DS_DM_PASSWORD=1234 \
  -e DS_SUFFIX=dc=example,dc=com \
  -e DS_INSTANCE_NAME=localhost \
  -e DS_INSTANCE_SCRIPT_UPDATES=yes \
  -e DS_ROOT_DN="cn=Directory Manager" \
  -e DS_SETUP_DS_SUFFIX=dc=example,dc=com \
  -e DS_SETUP_DS_DN="cn=Directory Manager" \
  -e DS_SETUP_DS_PASSWORD=1234 \
  -e DS_SETUP_ADMIN_USER=admin \
  -e DS_SETUP_ADMIN_PASSWORD=1234 \
  -v ldap_data:/data \
  --name ldap_server \
  registry.suse.com/suse/389-ds:latest

Allerdings fehlen in diesem Image wichtige Werkzeuge wie der vi.

# Ein paar Tools

## Podman
Stoppen des Containers:
> podman stop ldap_server

Löschen des Containers (Das Image bleibt erhalten):
> podman rm ldap_server

Sobald persistente Daten gebraucht werden, wird dieser Befehl hier interessant:
> podman run -d -p 3389:3389 -p 3636:3636 -e DS_DM_PASSWORD=1234 -v ldap_data:/data --name ldap_server 389ds/dirsrv:latest


## Linux Befehle
Einrichten und Bearbeiten von Serverinstanzen:
> dsidm localhost <action>

Zeigt an, ob der LDAP Server läuft:
> dsctl localhost healthcheck

## Windows
Es gibt für Windows auch LDAP-Browser. z.B. [hier](https://ldapbrowserwindows.com/)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23uFufPtfXzMQryFoXdAPusoteTrygJSGmrwmu36hZcDLznuB5jWCkrTV72SyzG5GxGpn.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EocDMVnX6xRM1c99WQGAR2rxWq7J2ErP6tDxp3kCtNavY7imrfggRBHWfmdKcUem2UZ.png)


# Base DN erstellen
Ich habe versucht einen User mit ldapadd zu erstellen, erhielt aber immer wieder die Fehlermeldung:
> ldap_add: No such object (32)
> 
... was bedeutet, dass ihm ein übergeordnetes Element (oder gar die Datenbank) fehlt.
Nach längerem Suchen bin ich schließlich auf folgende Lösung gestoßen:
> dsconf localhost backend create --suffix dc=example,dc=com --be-name userRoot --create-suffix

Parameter-Erklärung: 

- --suffix dc=example,dc=com: Definiert die zu erstellende Base-DN
- --be-name userRoot: Gibt dem Backend einen Namen (userRoot ist eine gängige Wahl)
- --create-suffix: Erstellt automatisch die Bas-DN im Verzeichnis
     
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGVhhN7gPs3MUgbrjz9jG13zwVykN7LNsc3oagYbno7VgGs2JNVDTJkuGkPedBkZhKH.png)


# Container erstellen
Benutzer liegen in einem Container. Daher ist dies eine Vorraussetzung, die wir hiermit schaffen. Wir erstellen eine Datei namens container.ldif mit folgendem Inhalt:
```
dn: ou=users,dc=example,dc=com
objectClass: organizationalUnit
ou: users

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups
```
Diese Datei fügen wir dann dem LDAP Server zu:

> ldapadd -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -f container.ldif

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tbK2FBgFe1QUvQfse3ksm9akRZtQoDL6ABxunNcC4q98zT15Famy4UwRfcBgUQWJhoE.png)

# User hinzufügen
Nun sind die Vorraussetzungen erfüllt um einen User zu erstellen.

user.ldif:
```
dn: uid=john.doe,ou=users,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
cn: John Doe
sn: Doe
uid: john.doe
uidNumber: 1000
gidNumber: 1000
homeDirectory: /home/john.doe
loginShell: /bin/bash
userPassword: {SSHA}passwordhash
```

> ldapadd -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -f user.ldif  

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tRxWiD1QoXqWp1cCqmCNG9dYDBGQ48UTDhottfVXfY3fcMbFvQEaveUxP7WsMgRqS3E.png)

> ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "dc=example,dc=com"

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo6BGDiQJxa43k3xcf8FJLXevLpqYMKKa7i2nAdGNPreBfn2aWgckBavkmTxnR5otPB.png)

# Userdaten ändern
Ich möchte z.B. das Passwort (auf etwas unkonventionellem Wege) des Users ändern.
Diese Änderungen speichere ich in einer password.ldif Datei ab:

```
dn: uid=john.doe,ou=users,dc=example,dc=com
changetype: modify
replace: userPassword
userPassword: xxx
```
Und schicke die Änderung dann an den LDAP Server:
> ldapmodify -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -f password.ldif

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tkhmLCddP2dP1MY8Hc4pKrRABBW3F7AYmjygvpdDqTEyAWqfBerZhzYZ1EAzzKA6Bsb.png)

# Fazit

Nun habe ich einen lauffähigen LDAP-Server, der von außen gelesen werden kann und auf dem der erste User existiert. Als nächsten Schritt möchte ich einen simplen NGNIX-Webserver erstellen, auf dem sich der User einloggen soll. Danach möchte ich User von dem IGA Server Midpoint exportieren und in LDAP einfügen. Und zu guter letzt soll noch ein Keycloak Server für die Authentifizierung angeschlossen werden. Da habe ich sicherlich noch einiges vor mir ;-)

Quellen für meine Doku: https://fy.blackhats.net.au/blog/2019-07-05-using-389ds-with-docker/
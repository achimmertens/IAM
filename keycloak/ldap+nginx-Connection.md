https://www.perplexity.ai/search/ich-habe-lokal-auf-meinem-pc-m-zCCOXrXZRlOYpeuEaVgdDQ

# Keycloak-Client für Nginx konfigurieren

 Erstellen Sie in Keycloak einen neuen OpenID Connect-Client:

 Client ID: z.B. nginx-client

 Client Protocol: openid-connect

 Access Type: confidential (für Client Secret)

 Redirect URI: https://<Ihre-Nginx-Domain>/oidc_callback 

Notieren Sie das Client Secret aus dem Keycloak-Admininterface
.

Konkret:
Aufrufen von Keycloak: http://localhost:8081/
Klicken auf "Administration Console"
Login mit admin admin
Clients/create client
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23xL9TJubBcqUn3yBAotn7vNA59ntricJ9UoG2fcyV1vZAQZYkvDvhVpdiGCx4ThCrj65.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CfKjHAuGbhZL3pLwjGFSxCW3mMgi2QaPMstXFJUw9Y2i2tLTuXTTiwhg1HHdsF7pL.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8DBnQEzrxfcQ3dcEddaQERrw8jKu4SrzSrkjp1AcwTbCLvUAJ6GGv7671s6Q8G679v.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8DBnQFMQYTUGzWNC3auHikYCQRJXCKz2pus2y8QCvkcadbeBg6JzNf5dDVfpFNUmNx.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CSPYK3e3KY4cN54pMfvExFmYZa5NHGeE4bPjvHCwMc3X31qrRpwGriYpejrjhJhbu.png)
U2hsQqdKHYUHp2g8LH7deMTJ5LR5n4iL

----------------------------------------

LDAP-Integration in Keycloak einrichten

    Gehen Sie in Keycloak zu User Federation → LDAP:

        Verbindungsparameter:

            LDAP-URL: ldap://<LDAP-Server-IP>

            Bind Type: simple

            Bind DN: Admin-DN des LDAP-Servers

            Bind Credentials: Passwort des LDAP-Admin

        Synchronisation aktivieren und Periodic Sync konfigurieren

Mapper für Attribute wie username, email und roles hinzufügen

Konkret:


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tvwZVmmK4w4vHRiLwjQkSKyyp9TeS32C26eWCqLsisTrcy2AZRytuJCXy2j75qhXiFH.png)

Eigentlich sollte als ldap-Adresse "ldap://ldap_server:3389" angegeben werden. Klappt bei mir aber nicht. Um die wahre LDAP-Adresse zu finden geben wir ein:

podman inspect ldap_server --format '{{.NetworkSettings.Networks.iam_network.IPAddress}}'

-> 10.89.1.7

Gehen Sie zu http://localhost:8081
Melden Sie sich als admin/admin an
Gehen Sie zu User Federation
Fügen Sie einen neuen LDAP Provider hinzu mit den folgenden Einstellungen:
Connection URL: ldap://ldap_server:3389
Enable StartTLS: OFF
Bind Type: simple
Bind DN: cn=Directory Manager
Bind Credentials: 1234
Users DN: ou=users,dc=example,dc=com
Username LDAP attribute: uid
RDN LDAP attribute: uid
UUID LDAP attribute: entryUUID
User Object Classes: inetOrgPerson, organizationalPerson, person


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EoCnzmcLgg5fFaU3PgzHfjrYQAbdgDGYVrgsZs3D8mRGjhL8tjJQCiRbddLCet2ED4V.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23sxjvEnxiQr4LNBBCPwLampyBpHByufQfi1FLGX5TkeeSByeeDHitXs7HH5dFTpXD5PA.png)
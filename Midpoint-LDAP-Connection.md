# Midpoint LDAP Connection

In dieser Dokumentation möchte ich zeigen, wie man in Midpoint einen User erstellt und diesen nach LDAP überträgt.
Der User soll in der Lage sein, LDAP zu nutzen um sich an einer Applikation zu authentifizieren.
Ich habe im Vorfeld einen leeren Midpointserver via Podman bei mir lokal gestartet (siehe [hier](https://peakd.com/hive-139531/@achimmertens/installation-eines-midpoint-docker-containers)) und ebenfsalls einen LDAP Server in einer Podman Installation gestartet.

Was mir jetzt also fehlt ist folgendes:
1. auf dem Midpointserver einen User anlegen
2. eine Appliaktion, die eine Authentifierung über meinen LDAP Server vornimmt
3. Mein LDAP Server muss mit dem Midpoint server verbunden sein und die Benutzerdaten erhalten.

Da ich noch nie mit einem LDAP-Server gearbeitet habe, ist es eine gewisse Herausforderung.
Aber legen wir los mit Punkt 1:
## Anlegen eines Users in Midpoint
Ich habe mir zunächst einen User namens Achim angelegt:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23w3AVLXt5aff9FNFgbtqKb25AvehnBiT1aZjAe5a2ymWphZBdo8W9humGyjXMm18KYkB.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tw5ZFZ9kZy3yyrjvYE8dRRzUEKdyoUYZHpmra1DrpuhBBcfBcBi3qX6NMmrPNZb83fB.png)

----
# Perplexiy empfiehlt folgende Architektur:
Um Midpoint, LDAP, Keycloak und Nginx in einem integrierten System für Accountverwaltung und Authentifizierung zu konfigurieren, empfehle ich folgende Architektur:
Midpoint

    Fungiert als zentrales Identity Management System
    Verwaltet Benutzerkonten und Berechtigungen
    Synchronisiert Benutzerdaten mit LDAP

LDAP

    Dient als zentrales Benutzerverzeichnis
    Wird von Midpoint als primäre Datenquelle verwendet
    Speichert Benutzer- und Gruppeninformationen

Keycloak

    Fungiert als Identity Provider (IdP) für Single Sign-On
    Authentifiziert Benutzer gegen LDAP
    Stellt OAuth 2.0 und OpenID Connect für Anwendungen bereit

Nginx

    Dient als Reverse Proxy und Zugangspunkt für Webanwendungen
    Leitet Authentifizierungsanfragen an Keycloak weiter

Konfigurationsschritte:

    Midpoint mit LDAP verbinden:
        Konfigurieren Sie einen LDAP-Ressourcenadapter in Midpoint
        Richten Sie Synchronisationsaufgaben für Benutzer und Gruppen ein
    Keycloak mit LDAP integrieren:
        Konfigurieren Sie einen LDAP-Benutzer-Federation-Provider in Keycloak
        Stellen Sie sicher, dass Keycloak Benutzer gegen LDAP authentifiziert
    Nginx mit Keycloak verbinden:
        Verwenden Sie das OpenID Connect-Modul für Nginx
        Konfigurieren Sie Nginx, um Authentifizierungsanfragen an Keycloak weiterzuleiten
    Midpoint als Keycloak-Client einrichten:
        Registrieren Sie Midpoint als Client in Keycloak
        Konfigurieren Sie Midpoint für die Verwendung von Keycloak zur Authentifizierung

Diese Konfiguration ermöglicht eine zentralisierte Accountverwaltung durch Midpoint, während Keycloak für SSO und Nginx für sicheren Zugriff auf Webanwendungen sorgt.

# Midpoint mit LDAP verbinden
## Starten des Midpoint servers:
### Initial:
Wir wechseln in das Midpoint Verzeichnis, welches [hier](https://github.com/Evolveum/midpoint-docker/tree/master) geholt werden kann und geben ein:
> podman compose up

[Details](https://peakd.com/hive-139531/@achimmertens/installation-eines-midpoint-docker-containers)

### Danach
Sobald der Server einmal eingerichtet wurde, liegt er als Podman Container vor und kann gestartet werden mit (in der Reihenfolge):

> podman start midpoint-midpoint_data-1
> 
> podman start midpoint-data_init-1
>
> podman start -a midpoint-midpoint_server-1

### Reset des Midpoint Servers
Man könnte auch die Container mit einem "podman compose up" starten und "podman compose down". Die Daten bleiben dabei erhalten, weil sie in einem Volume liegen. Dennoch ist es einfacher, die Container zu stoppen, anstatt sie immer zu löschen und neu anzulegen.
Wenn man die Daten aus Midpoint löschen/zurücksetzen will geht das wie folgt:
> podman compose down
>
> podman volume rm midpoint_midpoint_data
>
> podman compose up


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo8KedTu6pANpf3r3wqUDf9e1cUbk6YSXHvhUFdmtQc7s6DxXZbBEPrXdS8VaCYDa8B.png)
Damit ist der Midpoint Server wieder jungfräulich.

## LDAP Server starten
[Hier](https://peakd.com/hive-121566/@achimmertens/installation-eines-ldap-servers-via-podman-image) habe ich beschrieben, wie man einen LDAP-Server erstmalig als Podman Container startet und den ersten User anlegt.
Nun starten wir diesen Server in einem neuen Bash Terminal erneut mit:
> podman start -a ldap_server

Wir schauen, ob der erste User dort noch existiert. Dazu öffnen wir ein neues Terminal und geben dort ein:
> podman exec -it ldap_server bin/bash
>
> ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "dc=example,dc=com"

Der User sollte zu sehen sein:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tRrJB7iT2dncQj4UR8SN32vnz3uCuPbKtGeHrhf7DWGzkSiJqg7MUDYNAeeE75HFPjT.png)

## Midpoint mit LDAP connecten

In einem Browser geben wir ein: http://localhost:8082/
Username: Administrator
Passwort: Test5ecr3t

... und navigieren zu Ressources/new ressouce/from scratch und wählen dort den LDAP Connector:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo6Ri48iU6j5UaWAeTUnkQB5egqWAeUjazap9ieDij5KveTSArddugSkjQPJ4EXhLY1.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tcNngg1E5DSj5y9KrdVo3QVPgkGQQXNJXct3WaTHgBMSBzrcuHtti6GPF2Txu1YQr6d.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23u6Z4bLxwrZ7QHkTbbNFiY1kVt3adx1ceffehfvGYyiS6LDBeSZZgVmwEoqmGt8CYfHN.png)

Wichtig ist hier, dass anstelle von "localhost" "host.docker.internal" verwendet wird, da der Podman Container mit der Verwendung der IP-Adresse "localhost" nicht den Container verlässt.
Das Passwort ist hier 1234, welches wir beim LDAP Server gesetzt haben.

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHbg1MQVRYtDoLz47fNnYXnjPHN1TsCAfF6xbP9owAYHrygJpceCm3YGUSCvRmvHqWG.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo8ZeGKSwYa8DWh911Gw7zCE4FhSuk6L4wE8LgNiquaTrfa5z95tBdx7sMCSipWsKhE.png)




Wir testen, ob es funktioniert:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23viPHm8TcYeLa8Vuqq5yAfDxLYRYPU4eJ8fCAreLcwBwJYpEDnk1nFEcnGidcNqVoaDf.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/244y8cHPKXwsgKFp11jwXHNYB54MjX7KV84JqvoTFDRKLRtGeDGWUe1nrLNN6Ns5dkqE9.png)




# LDAP User importieren

Nun möchten wir die User von LDAP in Midpoint importieren. Dazu brauchen wir u.a. ein User Mapping und einen Import Task

Wir können es manuell erstellen:
## Import Task

Wir Klicken auf Server Tasks/All Tasks/New Task (Plus Symbol)/Import Task und füllen das Formular wie folgt aus:


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EogUbSJTFWbs6QPYkzGqVJSAQFxFHBLcYHecPSdPsiS56Ub4ESKEfbxiv1FYWR1qV5V.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tcNsR1Mjndq9L7bbwnkL8vrbEKg72jqc5VLTirUdbE2M8TKZMGtHqqiJSkgJ32FyKMM.png)



![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/48FmW93k7RjF8PVdz3dxeF6anTKLfPEstuMe9492c38ZZFuoKWDYunyVzrdPSNZr4t.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8AroUDknQ6CV9Jb4tUgP9yQaZg3wT5L4ty1Y3JE81Cj32RGNc94yXKjooSjnAvmvSB.png)

Speichern und laufen lassen:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSxGH5Jcpz4DdgPgrqjNAVpoBo8f7YXvz1eLKNgd3C8WZLBqshaFx6P4AgKwYMwtuVa.png)

## User Mapping
Wir erstellen ein Usermapping unter Resources/All Ressources/Achims_LDAP_Connector/Schema Handling/Object Types/Add Object Type:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8D1e7DZGzEgtVvVpdYs9RVwYdHjr5W3W27W8TUSf1r4TA8d3Xb9xbiVrFy2BdpFctY.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EoAgxYiMDmXMeqz95gLCA8GNpB6AbL2MuPBVmsrTHWgeGiKKCAWZC8WeK6UQ4FfYNEQ.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tcNnh1QLT2d2T2v7hvjKBgPPkjCKbDV6FUNEKXFU5YQyHdLrfPq2HqaBHPNXNFy8USf.png)



Nachdem das Schema Handling Objekt erstellt wurde, muss es editiert werden:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSx4Cq2DG3pjgwFLzbcBLQnobSBQF2xxPEJfrJ3SjUKXPR6uvrC6XUKjkpc2BkxPcoW.png)


Mappings:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CoaGtERprEcjasXq6ZiDCadLKz6x7VxyWkzWoPd3dSJZGZLyT5fjLBcfTiHBgDez5.png)

Links in den Namensfeldern einfach die Namen aus dem Ressource Attribut kopieren (Wenn einem nichts besseres einfällt):
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSz8K6X79Lpvd1zNjeet41Xu1xei91qnMwY2EK1mKPdMVk2jwgawWoaDnaSZJ8suguM.png)

## Import Lauf
Nachdem das Usermapping gemacht wurde, starten wir den ersten Importlauf:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23u6UYsGX8HZZW1e82hhuuK5zW5GjnRDPX52aKAwXUJbcivhTdcc5m9DaxubvAgBewEPg.png)


Beim ersten Lauf des Import Tasks wird es zwar eine Fehlermeldung geben, dass die Account keinem User zugeordnet sind, die Accounts werden aber angelegt.
Erst nachdem jeder Account mit einem Benutzer verknüpft ist, verschwindet die Fehlermeldung.

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23viREhD9n2GA69fqKcqMZ32pRwpd3dnchatpKC94GxgkHoSPQYqUanGCYprb3Qeo96Lw.png)





------




```
<?xml version="1.0" encoding="UTF-8"?>
<resource xmlns="http://midpoint.evolveum.com/xml/ns/public/common/common-3"
          xmlns:q="http://prism.evolveum.com/xml/ns/public/query-3"
          xmlns:icfc="http://midpoint.evolveum.com/xml/ns/public/connector/icf-1/connector-schema-3"
          xmlns:icfs="http://midpoint.evolveum.com/xml/ns/public/connector/icf-1/resource-schema-3"
          xmlns:icfcldap="http://midpoint.evolveum.com/xml/ns/public/connector/icf-1/bundle/com.evolveum.polygon.connector-ldap/com.evolveum.polygon.connector.ldap.LdapConnector"
          xmlns:t="http://prism.evolveum.com/xml/ns/public/types-3"
          oid="44444444-4444-4444-4444-000000000000">
    <name>Local LDAP Server</name>
    <description>Connection to the local LDAP server</description>

    <!-- Connector-Referenz -->
    <connectorRef type="ConnectorType">
        <filter>
            <q:equal>
                <q:path>connectorType</q:path>
                <q:value>com.evolveum.polygon.connector.ldap.LdapConnector</q:value>
            </q:equal>
        </filter>
    </connectorRef>

    <!-- Connector-Konfiguration -->
    <connectorConfiguration>
        <icfc:configurationProperties>
            <icfcldap:host>host.docker.internal</icfcldap:host>
            <icfcldap:port>3389</icfcldap:port>
            <icfcldap:baseContext>dc=example,dc=com</icfcldap:baseContext>
            <icfcldap:bindDn>cn=Directory Manager</icfcldap:bindDn>
            <icfcldap:bindPassword>
                <t:clearValue>1234</t:clearValue>
            </icfcldap:bindPassword>
        </icfc:configurationProperties>
    </connectorConfiguration>

    <!-- Schema Handling -->
    <schemaHandling>
        <objectType>
            <kind>account</kind>
            <default>true</default>
            <objectClass>inetOrgPerson</objectClass>
            <auxiliaryObjectClass>posixAccount</auxiliaryObjectClass>

            <!-- Attribute-Mapping -->
            <attribute>
                <ref>uid</ref>
                <displayName>Username</displayName>
                <outbound>
                    <source>
                        <path>$user/name</path>
                    </source>
                </outbound>
                <inbound>
                    <target>
                        <path>$user/name</path>
                    </target>
                </inbound>
            </attribute>

            <attribute>
                <ref>cn</ref>
                <displayName>Full Name</displayName>
                <outbound>
                    <source>
                        <path>$user/fullName</path>
                    </source>
                </outbound>
                <inbound>
                    <target>
                        <path>$user/fullName</path>
                    </target>
                </inbound>
            </attribute>

            <attribute>
                <ref>sn</ref>
                <displayName>Last Name</displayName>
                <outbound>
                    <source>
                        <path>$user/familyName</path>
                    </source>
                </outbound>
                <inbound>
                    <target>
                        <path>$user/familyName</path>
                    </target>
                </inbound>
            </attribute>

            <attribute>
                <ref>uidNumber</ref>
                <displayName>UID Number</displayName>
                <outbound>
                    <source>
                        <path>$user/extension/uidNumber</path>
                    </source>
                </outbound>
                <inbound>
                    <target>
                        <path>$user/extension/uidNumber</path>
                    </target>
                </inbound>
            </attribute>

            <attribute>
                <ref>gidNumber</ref>
                <displayName>GID Number</displayName>
                <outbound>
                    <source>
                        <path>$user/extension/gidNumber</path>
                    </source>
                </outbound>
                <inbound>
                    <target>
                        <path>$user/extension/gidNumber</path>
                    </target>
                </inbound>
            </attribute>

            <attribute>
                <ref>homeDirectory</ref>
                <displayName>Home Directory</displayName>
                <outbound>
                    <source>
                        <path>$user/extension/homeDirectory</path>
                    </source>
                </outbound>
                <inbound>
                    <target>
                        <path>$user/extension/homeDirectory</path>
                    </target>
                </inbound>
            </attribute>

            <attribute>
                <ref>loginShell</ref>
                <displayName>Login Shell</displayName>
                <outbound>
                    <source>
                        <path>$user/extension/loginShell</path>
                    </source>
                </outbound>
                <inbound>
                    <target>
                        <path>$user/extension/loginShell</path>
                    </target>
                </inbound>
            </attribute>
        </objectType>
    </schemaHandling>

    <synchronization>
        <objectSynchronization>
            <enabled>true</enabled>
            <correlation>
                <q:equal>
                    <q:path>name</q:path>
                    <expression>
                        <path>$account/attributes/uid</path>
                    </expression>
                </q:equal>
            </correlation>
            <reaction>
                <situation>unlinked</situation>
                <action>
                    <handlerUri>http://midpoint.evolveum.com/xml/ns/public/model/action-3#addFocus</handlerUri>
                </action>
            </reaction>
            <reaction>
                <situation>unmatched</situation>
                <action>
                    <handlerUri>http://midpoint.evolveum.com/xml/ns/public/model/action-3#addFocus</handlerUri>
                </action>
            </reaction>
        </objectSynchronization>
    </synchronization>
</resource>
```

Nachdem Sie die Ressourcenkonfiguration aktualisiert haben:

a) Gehen Sie im MidPoint-Menü zu "Konfiguration" > "Importieren von Objekten".
b) Wählen Sie Ihre aktualisierte Ressourcenkonfigurationsdatei aus und importieren Sie sie.
c) Gehen Sie dann zu "Server-Aufgaben" > "Neue Aufgabe".
d) Wählen Sie "Reconciliation" als Aufgabentyp.
e) Wählen Sie Ihre LDAP-Ressource als Ziel aus.
f) Speichern und führen Sie die Aufgabe aus.

Den Task starten und warten (30 Minuten?). Zumindest taucht der User schon mal im Home Dashboard auf:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23xpTggek7SdK56Np9qcjQBkEYhE3nhtLxFLyPGM9ifho7988D1MTeA4zkC44uLEYYtwi.png)

Nachdem ein Account importiert wurde, kann er einem User zugeordnet werden.
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo2Auffk1YDXaAuaG5DZ46TWLTWRyA2hXSz7VvQFoDKWKcN1ea1GBF9PpYaDF33s4B4.png)

Das kann man sicherlich automatisieren, indem man das Mapping verfeinert, ich breche das hier aber erst mal ab, weil es mir nur darum ging, einen Import durchzuführen.

# User Export nach LDAP


# Backup der Volumes erstellen




Wir können nun in Midpoint sehen, welche LDAP User es gibt und diese auch importieren:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZbuWV3DhnCbqE2hjvMH3T5NvmH4KFxnoSK48MJGHUcwEdED8wFdXqBL1Ug57CqbJf.png)

# Midpoint LDAP Connection

In dieser Dokumentation möchte ich zeigen, wie man in Midpoint einen User erstellt und diesen nach LDAP überträgt.

Ich habe im Vorfeld einen leeren Midpointserver via Podman bei mir lokal gestartet (siehe [hier](https://peakd.com/hive-139531/@achimmertens/installation-eines-midpoint-docker-containers)) und ebenfsalls einen LDAP Server in einer Podman Installation gestartet.

Was ich jetzt machen möchte ist folgendes:
1. auf dem Midpointserver einen User anlegen
2. auf dem Midpointserver User aus einer Datei importieren
3. Midpoint und LDAP verbinden
4. Ldap Daten Lesen und in Midpoint importieren
5. Midpoint User nach LDAP schreiben

Da ich noch nie sowohl mit Midpoint noch mit einem LDAP-Server gearbeitet habe, ist es eine gewisse Herausforderung.
Aber legen wir los mit Punkt 1:

# User anlegen auf Midpoint
## Starten des Midpoint servers:
### Initial:
Wir wechseln in das Midpoint Verzeichnis, welches [hier](https://github.com/Evolveum/midpoint-docker/tree/master) geholt werden kann und geben ein:
> podman compose up

Details dazu habe ich [hier](https://peakd.com/hive-139531/@achimmertens/installation-eines-midpoint-docker-containers) beschrieben.

### Danach
Sobald der Server einmal eingerichtet wurde, liegt er als Podman Container vor und kann gestartet werden mit (in der Reihenfolge):

> podman start midpoint-midpoint_data-1
> 
> podman start midpoint-data_init-1
>
> podman start -a midpoint-midpoint_server-1

Gestoppt wird der Server in der Konsole mit STRG-x oder dem Löschen des Terminals in dem der Server läuft.

### Reset des Midpoint Servers
Man könnte nach der Installation auch die Container mit einem "podman compose up" neu erstellen und mit "podman compose down" löschen. Die Daten bleiben dabei erhalten, weil sie in einem Volume liegen. Dennoch ist es einfacher, die Container zu stoppen, anstatt sie immer zu löschen und neu anzulegen.

Wenn man die Daten aus Midpoint löschen/zurücksetzen will geht das wie folgt:
> podman compose down
>
> podman volume rm midpoint_midpoint_data
>
> podman compose up


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo8KedTu6pANpf3r3wqUDf9e1cUbk6YSXHvhUFdmtQc7s6DxXZbBEPrXdS8VaCYDa8B.png)
Damit ist der Midpoint Server wieder jungfräulich.

## Anlegen eines Users in Midpoint
In einem Browser geben wir ein: http://localhost:8082/
Username: Administrator
Passwort: Test5ecr3t

Ich habe mir zunächst einen User namens Achim angelegt. Dazu bin ich in der Adminoberfläche auf Benutzer gegangen und habe dort mit dem "+" Symbol einfach einen neuen User angelegt

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23w3AVLXt5aff9FNFgbtqKb25AvehnBiT1aZjAe5a2ymWphZBdo8W9humGyjXMm18KYkB.png)

## Import von Usern aus einer Datei

Ich habe eine Datei erstellt mit folgendem Inhalt:
```
[
    {
        "user": {
            "name": "beispielmitarbeiter", 
            "givenName": "Max",
            "familyName": "Mustermann",
            "fullName": "Max Mustermann",
            "employeeNumber": "12345",
            "assignment": [ 
                {
                    "targetRef": {
                        "oid": "86d3b462-2334-11ea-bbac-13d84ce0a1df",
                        "type": "RoleType"
                    }
                }
            ]
        }
    },
    {
        "user": {
            "name": "Ali Mente", 
            "givenName": "Ali",
            "familyName": "Mente",
            "fullName": "Ali Mente",
            "employeeNumber": "12346",
            "assignment": [ 
                {
                    "targetRef": {
                        "oid": "86d3b462-2334-11ea-bbac-13d84ce0a1df",
                        "type": "RoleType"
                    }
                }
            ]
        }
    },
    {
        "user": {
            "name": "Rudi Mente", 
            "givenName": "Rudi",
            "familyName": "Mente",
            "fullName": "Rudi Mente",
            "employeeNumber": "12347",
            "assignment": [ 
                {
                    "targetRef": {
                        "oid": "86d3b462-2334-11ea-bbac-13d84ce0a1df",
                        "type": "RoleType"
                    }
                }
            ]
        }
    }
]
```
Nach dem Klicken auf das Import Symbol (rechts neben dem "+") konnte ich die User importieren:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tw5ZFZCjmbYF7pw6GQr7jLy4aNqyFDPn1dtiLb3dhRsaCBGr2X7D8KUCAh3EHuQGBgm.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EoH4Eji2JiCof6xx9vpfhiLwm1CM5BCfcjHNoTBCf7Gh7zmXFfnVF89toKvd4vGAQHX.png)



# LDAP Server starten
[Hier](https://peakd.com/hive-121566/@achimmertens/installation-eines-ldap-servers-via-podman-image) habe ich beschrieben, wie man einen LDAP-Server erstmalig als Podman Container startet und den ersten User anlegt.
Nun starten wir diesen Server in einem neuen Bash Terminal erneut mit:
> podman start -a ldap_server

Wir schauen, ob der erste User dort noch existiert. Dazu öffnen wir ein neues Terminal und geben dort ein:
> podman exec -it ldap_server bin/bash
>
> ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "dc=example,dc=com"

Der User sollte zu sehen sein:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tRrJB7iT2dncQj4UR8SN32vnz3uCuPbKtGeHrhf7DWGzkSiJqg7MUDYNAeeE75HFPjT.png)

# Midpoint mit LDAP connecten

## Manuell
Um es vorwegzunehmen, der Manuelle Weg klappt bei mir nicht richtig. Ich bekomme zwar eine Testverbiundung hing, kann aber keine Personen Importiern. Ich habe wahrscheinlich etwas übersehen. Dennoch dokumentiere ich hier, wie weit ich gekommen bin, weil einige Erkenntnisse wichtig sind. Ihr könnt das Kapitel überspringen zu "LDAP User Importieren via XML".

Wir navigieren in Midpoint zu Ressources/new ressouce/from scratch und wählen dort den LDAP Connector:

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




## LDAP User importieren via XML

Nun möchten wir die User von LDAP in Midpoint importieren. Dazu brauchen wir eine Ressourcendefinition mit eoinem Usermapping und einen Import Task

### Resourcendefinition + Mapping 
Das Usermapping übernehmen wir direkt mit in der XML Datei, die auch die Resourcendefinition erstellt.
Dazu klicken wir auf Resources/All Resources und dort das Import Symbol:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tcLdrNP59JXHAwHoDUUz3c6QF8bHdTBAYjM6UgQDfJkoZoBQioG9hukaQhZx4JS39Uy.png)
Dann impotrieren wir folgende Resourcedefinition:

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

### User Mapping
Die Usermappings wurden mit dem XML erstellt. Wir brauchen hier eigentlich nichts zu tun. Falls wir doch mal nachschauen oder etwas ändern wollen, geht das wie folgt: Wir finden die Mappings unter Resources/All Ressources/Local LDAP Server/Schema Handling/Object Types:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZgM8nCqmEW6dzMf8WWEoHHqQNvV4dPzm5iwMuG4yk7SpiF7u3y1CgG8pvypMBUELg.png)

... Mappings:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CoaGtERprEcjasXq6ZiDCadLKz6x7VxyWkzWoPd3dSJZGZLyT5fjLBcfTiHBgDez5.png)

Wenn man sie verändern will, muss links in den Namensfeldern noch Werte eingetragen werden. Ich habe einfach die Namen aus dem Ressource Attribut kopiert:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSz8K6X79Lpvd1zNjeet41Xu1xei91qnMwY2EK1mKPdMVk2jwgawWoaDnaSZJ8suguM.png)



## Import Task erstellen

Wir Klicken auf Server Tasks/All Tasks/New Task (Plus Symbol)/Import Task und füllen das Formular wie folgt aus:


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EogUbSJTFWbs6QPYkzGqVJSAQFxFHBLcYHecPSdPsiS56Ub4ESKEfbxiv1FYWR1qV5V.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tcNsR1Mjndq9L7bbwnkL8vrbEKg72jqc5VLTirUdbE2M8TKZMGtHqqiJSkgJ32FyKMM.png)

So sieht der fertige Task aus:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CsxKLiC3kqvKUpZYhjqQ1wktWAwfRu7dj826tz156NzkV2F54s7AyHB3oADSu1GgG.png)



## Import Laufen lassen
Wir haben nun eine Resourcendefinition mit einem Usermapping und einen Importtask.
Wir starten nun den ersten Importlauf:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23u6UYsGX8HZZW1e82hhuuK5zW5GjnRDPX52aKAwXUJbcivhTdcc5m9DaxubvAgBewEPg.png)

Die Ergebnisse des Imports stehen unter "Results" oder "Errors":
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZbuv1orxBv4KnPrinXgESW7xR6kYJBfrf2kHPN3TCUuHPsz6BHQh5Stub2ZfcSKUz.png)


Wenn alles klappt, werden User als Accounts der Ressource zugefügt.
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tmhJWmWEVuZeBm4ZGqAkzBiYhrgHorepvgYZMinfcF1qQXxjNX9Cn5E2Xfr65vyJnZ9.png)
sie sind damit aber sogenannte Schattenaccounts, die noch mkeinemUser zugeordnet sind. Das könnte man rechts über den Knopf "Change Owner" erledigen, elegantzer ist aber ein Reconciliation Task:



## Reconcoliation Task erstellen und laufen lassen
Unter Server Tasks erstellen wir einen neuen Reconciliation Task:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23vspBrjugvKSdKnUqvFEXogsrdSzoTmUrVtk7uitSZus6ym8hQ2vSDZysA9vMtRxZhCN.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSxLiiHy33yE8XGPtcmF62iD5miRuscjHMuELWuprn4gdsexpHjxHdKmSELYHvRhw28.png)

Dieser importiert die LDAP User auch als User in Midpoint. D.h. es werden zuerst Accounts erstellt und dann User, die mit diesen Accounts verknüpft sind:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tmj5gRJXkYDDbX2FRE9tBH7xZyaqVJoZvBfowd7HgXBtVq4KYn6yjRAUxmk956T8mPo.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSxGH5zrQDqK1tkPw1xwvQpyRPmUtUx59fPpTnLK5sG9119M2tT8yeaZ8wWswaex1iM.png)










# User Export nach LDAP


# Backup der Volumes erstellen




Wir können nun in Midpoint sehen, welche LDAP User es gibt und diese auch importieren:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZbuWV3DhnCbqE2hjvMH3T5NvmH4KFxnoSK48MJGHUcwEdED8wFdXqBL1Ug57CqbJf.png)

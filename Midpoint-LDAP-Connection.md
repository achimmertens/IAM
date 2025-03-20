# Inhalt

In dieser Dokumentation möchte ich zeigen, wie man in dem Identity Governant Access (IGA) System "Midpoint" User nach LDAP überträgt.

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EowMwAoMdC61XSzGqZitfwZmwgqh8cHUdAX8qnjNPS5maLaUDNHexMTDUhXAypfP7S8.png)

Ich habe im Vorfeld folgendes dokumentiert:
1. Installation eines leeren Midpointservers (IGA) via Podman  (siehe [Punkt 1](https://peakd.com/hive-139531/@achimmertens/installation-eines-midpoint-docker-containers))
2. Installation eines LDAP Podman Servers (siehe [Punkt 2](https://peakd.com/hive-121566/@achimmertens/installation-eines-ldap-servers-via-podman-image))
3. Installation eines Keyclock Podman Servers (siehe [Punkt 3](https://peakd.com/hive-121566/@achimmertens/keycloak-eine-software-die-den-zugriff-regelt))
4.  Ein hr.csv Import in den Midpoint Server (siehe [Punkt 4](https://peakd.com/hive-121566/@achimmertens/wie-man-eine-hrcsv-user-datei-in-dem-iga-server-midpoint-importiert)).



Hier, mit Punkt 5, beschreibe ich, wie ich diese User in meinen LDAP Server übertrage:

## Inhaltstabelle:
- [Inhalt](#inhalt)
  - [Inhaltstabelle:](#inhaltstabelle)
- [LDAP Server starten](#ldap-server-starten)
- [Alle Services gleichzeitig starten mit Visual Studio Code](#alle-services-gleichzeitig-starten-mit-visual-studio-code)
- [Midpoint mit LDAP connecten](#midpoint-mit-ldap-connecten)
  - [1. LDAP User importieren via XML](#1-ldap-user-importieren-via-xml)
    - [1.1 Resourcendefinition laden](#11-resourcendefinition-laden)
    - [1.2 Usermapping ggf. anpassen](#12-usermapping-ggf-anpassen)
    - [1.3 Import Task erstellen](#13-import-task-erstellen)
    - [1.4 Import Laufen lassen](#14-import-laufen-lassen)
  - [2. Reconcoliation Task erstellen und laufen lassen](#2-reconcoliation-task-erstellen-und-laufen-lassen)
  - [3. HR User Export nach LDAP](#3-hr-user-export-nach-ldap)
- [Fazit](#fazit)


# LDAP Server starten
Wie erwähnt, hatte ich in [Punkt 1](https://peakd.com/hive-121566/@achimmertens/installation-eines-ldap-servers-via-podman-image) beschrieben, wie man einen LDAP-Server erstmalig als Podman Container startet und den ersten User anlegt.
Nun starten wir diesen Server in einem neuen Bash Terminal erneut mit:
> podman start -a ldap_server

Wir schauen, ob der erste User dort noch existiert. Dazu öffnen wir ein neues Terminal und geben dort ein:
> podman exec -it ldap_server bin/bash
>
> ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "dc=example,dc=com"

Der User sollte zu sehen sein:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tRrJB7iT2dncQj4UR8SN32vnz3uCuPbKtGeHrhf7DWGzkSiJqg7MUDYNAeeE75HFPjT.png)

# Alle Services gleichzeitig starten mit Visual Studio Code
Es ist mühselig, die Server jeweils in einer Konsole zu starten. Ich habe ja auch noch den Midpoint-, Keycloak- und Nginx-Server im Gepäck.
Daher habe ich mir eine Task.json Datei im Ordner .vscode angelegt mit folgendem Inhalt:

```
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Start All Services",
            "dependsOn": [
                "Midpoint Server",
                "Midpoint Shell",
                "Keycloak Server",
                "LDAP Server",
                "LDAP Shell",
                "Nginx Server"
            ],
            "problemMatcher": [],
            "isBackground": true
        },
        {
            "label": "Midpoint Server",
            "type": "shell",
            "command": "cd ${workspaceFolder}/midpoint && ./start_midpoint_server.sh",
            "options": {
                "cwd": "${workspaceFolder}/midpoint"
            },
            "presentation": {
                "reveal": true,
                "panel": "new",
                "clear": true,
                "title": "Midpoint Server"
            },
            "problemMatcher": [],
            "isBackground": true
        },
        {
            "label": "Midpoint Shell",
            "type": "shell",
            "command": "sleep 20 && cd ${workspaceFolder}/midpoint && ./start_midpoint_shell.sh",
            "options": {
                "cwd": "${workspaceFolder}/midpoint"
            },
            "presentation": {
                "reveal": true,
                "panel": "new",
                "clear": true,
                "title": "Midpoint Shell"
            },
            "problemMatcher": [],
            "isBackground": true
        },
        {
            "label": "Keycloak Server",
            "type": "shell",
            "command": "cd ${workspaceFolder}/keycloak && ./start_keycloak_server.sh",
            "options": {
                "cwd": "${workspaceFolder}/keycloak"
            },
            "presentation": {
                "reveal": true,
                "panel": "new",
                "clear": true,
                "title": "Keycloak Server"
            },
            "problemMatcher": [],
            "isBackground": true
        },
        {
            "label": "LDAP Server",
            "type": "shell",
            "command": "cd ${workspaceFolder}/ldap && ./start_ldap_server.sh",
            "options": {
                "cwd": "${workspaceFolder}/ldap"
            },
            "presentation": {
                "reveal": true,
                "panel": "new",
                "clear": true,
                "title": "LDAP Server"
            },
            "problemMatcher": [],
            "isBackground": true
        },
        {
            "label": "LDAP Shell",
            "type": "shell",
            "command": "sleep 20 && cd ${workspaceFolder}/ldap && ./start_ldap_client.sh",
            "options": {
                "cwd": "${workspaceFolder}/ldap"
            },
            "presentation": {
                "reveal": true,
                "panel": "new",
                "clear": true,
                "title": "LDAP Client"
            },
            "problemMatcher": [],
            "isBackground": true
        },
        {
            "label": "Nginx Server",
            "type": "shell",
            "command": "cd ${workspaceFolder}/nginx && ./start_nginx.sh",
            "options": {
                "cwd": "${workspaceFolder}/nginx"
            },
            "presentation": {
                "reveal": true,
                "panel": "new",
                "clear": true,
                "title": "Nginx"
            },
            "problemMatcher": [],
            "isBackground": true
        }
    ]
}
```
Wenn man nun das VSStudio Code neu startet, kann man mit Strg+Shift+p den Befehl "Run Tasks" eingeben und dann "Start All Services" anklicken. Als Ergebnis öffnen sich mehrere Shell Konsolen in denen die Server gestartet werden:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t7AyRxj3RBvn8btYpGevMbQBpmcK3xdpgMezRW2sVjM8PxsA9zFSdLESxwEFoBmby7n.png)


# Midpoint mit LDAP connecten
Wir haben nun folgende Ziele:
1. Wir wollen User aus LDAP in Midpoint einlesen (LDAP Import)
2. Wir wollen diese User verändern und nach LDAP schreiben (Reconciliation)
3. Wir wollen User, die aus HR kommen nach LDAP übertragen (HR.csv Import + Reconciliation nach LDAP)




## 1. LDAP User importieren via XML

Nun möchten wir die User von LDAP in Midpoint importieren. Dazu brauchen wir eine Ressourcendefinition mit einem Usermapping und einen Import Task.

### 1.1 Resourcendefinition laden 
Das Usermapping übernehmen wir direkt mit in der XML Datei, die auch die Resourcendefinition erstellt.
Dazu klicken wir auf Resources/All Resources und dort das Import Symbol:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tcLdrNP59JXHAwHoDUUz3c6QF8bHdTBAYjM6UgQDfJkoZoBQioG9hukaQhZx4JS39Uy.png)
Dann importieren wir folgende Resourcedefinition ([Quelle](https://github.com/Evolveum/midpoint-book/blob/master/samples/5/resource-ldap.xml)):
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

### 1.2 Usermapping ggf. anpassen
Die Usermappings wurden mit dem XML erstellt. Wir brauchen hier eigentlich nichts zu tun. Falls wir doch mal nachschauen oder etwas ändern wollen, geht das wie folgt: Wir finden die Mappings unter Resources/All Ressources/Local LDAP Server/Schema Handling/Object Types:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZgM8nCqmEW6dzMf8WWEoHHqQNvV4dPzm5iwMuG4yk7SpiF7u3y1CgG8pvypMBUELg.png)

... Mappings:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CoaGtERprEcjasXq6ZiDCadLKz6x7VxyWkzWoPd3dSJZGZLyT5fjLBcfTiHBgDez5.png)

Wenn man sie verändern will, muss links in den Namensfeldern noch Werte eingetragen werden. Ich habe einfach die Namen aus dem Ressource Attribut kopiert:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSz8K6X79Lpvd1zNjeet41Xu1xei91qnMwY2EK1mKPdMVk2jwgawWoaDnaSZJ8suguM.png)



### 1.3 Import Task erstellen

Wir Klicken auf Server Tasks/All Tasks/New Task (Plus Symbol)/Import Task und füllen das Formular wie folgt aus:


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EogUbSJTFWbs6QPYkzGqVJSAQFxFHBLcYHecPSdPsiS56Ub4ESKEfbxiv1FYWR1qV5V.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tcNsR1Mjndq9L7bbwnkL8vrbEKg72jqc5VLTirUdbE2M8TKZMGtHqqiJSkgJ32FyKMM.png)

So sieht der fertige Task aus:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CsxKLiC3kqvKUpZYhjqQ1wktWAwfRu7dj826tz156NzkV2F54s7AyHB3oADSu1GgG.png)



### 1.4 Import Laufen lassen
Wir haben nun eine Resourcendefinition mit einem Usermapping und einen Importtask.
Wir starten nun den ersten Importlauf:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23u6UYsGX8HZZW1e82hhuuK5zW5GjnRDPX52aKAwXUJbcivhTdcc5m9DaxubvAgBewEPg.png)

Die Ergebnisse des Imports stehen unter "Results" oder "Errors":
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZbuv1orxBv4KnPrinXgESW7xR6kYJBfrf2kHPN3TCUuHPsz6BHQh5Stub2ZfcSKUz.png)


Wenn alles klappt, werden User als Accounts der Ressource zugefügt.
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tmhJWmWEVuZeBm4ZGqAkzBiYhrgHorepvgYZMinfcF1qQXxjNX9Cn5E2Xfr65vyJnZ9.png)
Sie sind damit aber sogenannte Schattenaccounts, die noch keinem User zugeordnet sind. Das könnte man rechts über den Knopf "Change Owner" erledigen, eleganter ist aber ein Reconciliation Task:



## 2. Reconcoliation Task erstellen und laufen lassen
Unter Server Tasks erstellen wir einen neuen Reconciliation Task:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23vspBrjugvKSdKnUqvFEXogsrdSzoTmUrVtk7uitSZus6ym8hQ2vSDZysA9vMtRxZhCN.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSxLiiHy33yE8XGPtcmF62iD5miRuscjHMuELWuprn4gdsexpHjxHdKmSELYHvRhw28.png)

Dieser importiert die LDAP User auch als User in Midpoint. D.h. es werden zuerst Accounts erstellt und dann User, die mit diesen Accounts verknüpft sind:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tmj5gRJXkYDDbX2FRE9tBH7xZyaqVJoZvBfowd7HgXBtVq4KYn6yjRAUxmk956T8mPo.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSxGH5zrQDqK1tkPw1xwvQpyRPmUtUx59fPpTnLK5sG9119M2tT8yeaZ8wWswaex1iM.png)


## 3. HR User Export nach LDAP

Viel spannender als LDAP User zu syncronisieren, ist natürlich, User, die wir mit einem [HR Import](https://peakd.com/hive-121566/@achimmertens/wie-man-eine-hrcsv-user-datei-in-dem-iga-server-midpoint-importiert) erhalten haben, nach LDAP zu provisionieren.
Folgende Resourcendefinition ([Quelle](https://github.com/Evolveum/midpoint-book/blob/master/samples/4/resource-ldap.xml)) baut eine Verbindung zum LDAP Server auf und ermöglicht eine Übertragung der User in dem Format, das der LDAP Server versteht:

```
<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ Copyright (c) 2010-2023 Evolveum
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~     http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  -->

<resource oid="8a83b1a4-be18-11e6-ae84-7301fdab1d7c"
    xmlns="http://midpoint.evolveum.com/xml/ns/public/common/common-3"
    xmlns:c="http://midpoint.evolveum.com/xml/ns/public/common/common-3"
    xmlns:t='http://prism.evolveum.com/xml/ns/public/types-3'
    xmlns:ri="http://midpoint.evolveum.com/xml/ns/public/resource/instance-3"
    xmlns:icfs="http://midpoint.evolveum.com/xml/ns/public/connector/icf-1/resource-schema-3"
    xmlns:icfc="http://midpoint.evolveum.com/xml/ns/public/connector/icf-1/connector-schema-3"
    xmlns:q="http://prism.evolveum.com/xml/ns/public/query-3"
    xmlns:mr="http://prism.evolveum.com/xml/ns/public/matching-rule-3"
    xmlns:cap="http://midpoint.evolveum.com/xml/ns/public/resource/capabilities-3">

    <name>LDAP</name>

    <description>
        LDAP resource using a ConnId LDAP connector. It contains configuration
        for use with OpenLDAP servers.
        This is a sample used in the "Practical Identity Management with MidPoint"
        book, chapter 4.
    </description>

    <connectorRef type="ConnectorType">
        <filter>
            <q:text>connectorType = "com.evolveum.polygon.connector.ldap.LdapConnector"</q:text>
        </filter>
    </connectorRef>

    <connectorConfiguration
            xmlns:icfc="http://midpoint.evolveum.com/xml/ns/public/connector/icf-1/connector-schema-3"
            xmlns:icfcldap="http://midpoint.evolveum.com/xml/ns/public/connector/icf-1/bundle/com.evolveum.polygon.connector-ldap/com.evolveum.polygon.connector.ldap.LdapConnector">
        <icfc:configurationProperties>
            <icfcldap:port>3389</icfcldap:port>
            <icfcldap:host>host.docker.internal</icfcldap:host>
            <icfcldap:baseContext>dc=example,dc=com</icfcldap:baseContext>
            <icfcldap:bindDn>cn=Directory Manager</icfcldap:bindDn>
            <icfcldap:bindPassword><t:clearValue>1234</t:clearValue></icfcldap:bindPassword>
            <icfcldap:passwordHashAlgorithm>SSHA</icfcldap:passwordHashAlgorithm>
            <icfcldap:vlvSortAttribute>uid,cn,ou,dc</icfcldap:vlvSortAttribute>
            <icfcldap:vlvSortOrderingRule>2.5.13.3</icfcldap:vlvSortOrderingRule>
            <icfcldap:operationalAttributes>memberOf</icfcldap:operationalAttributes>
            <icfcldap:operationalAttributes>createTimestamp</icfcldap:operationalAttributes>
        </icfc:configurationProperties>
    </connectorConfiguration>

    <!-- The schema will be generated by midPoint when the resource is first used -->

    <schemaHandling>
        <objectType>
            <kind>account</kind>
            <displayName>Normal Account</displayName>
            <default>true</default>
            <delineation>
                <objectClass>inetOrgPerson</objectClass>
            </delineation>

            <attribute>
                <ref>dn</ref>
                <displayName>Distinguished Name</displayName>
                <limitations>
                    <minOccurs>0</minOccurs>
                </limitations>
                <outbound>
                    <source>
                        <path>$focus/name</path>
                    </source>
                    <expression>
                        <script>
                            <code>
                                basic.composeDnWithSuffix('uid', name, 'ou=users,dc=example,dc=com')
                            </code>
                        </script>
                    </expression>
                </outbound>
            </attribute>
            <attribute>
                <ref>entryUUID</ref>
                <displayName>Entry UUID</displayName>
            </attribute>
            <attribute>
                <ref>cn</ref>
                <displayName>Common Name</displayName>
                <limitations>
                    <minOccurs>0</minOccurs>
                </limitations>
                <outbound>
                    <source>
                        <path>$focus/fullName</path>
                    </source>
                </outbound>
            </attribute>
            <attribute>
                <ref>sn</ref>
                <displayName>Surname</displayName>
                <limitations>
                    <minOccurs>0</minOccurs>
                </limitations>
                <outbound>
                    <source>
                        <path>$focus/familyName</path>
                    </source>
                </outbound>
            </attribute>
            <attribute>
                <ref>givenName</ref>
                <displayName>Given Name</displayName>
                <outbound>
                    <source>
                        <path>$focus/givenName</path>
                    </source>
                </outbound>
            </attribute>
            <attribute>
                <ref>uid</ref>
                <displayName>Login Name</displayName>
                <outbound>
                    <strength>weak</strength>
                    <source>
                        <path>$focus/name</path>
                    </source>
                </outbound>
            </attribute>
            <attribute>
                <ref>description</ref>
                <outbound>
                    <strength>weak</strength>
                    <expression>
                        <value>Created by midPoint</value>
                    </expression>
                </outbound>
            </attribute>

            <activation>
                <administrativeStatus>
                    <outbound/>
                </administrativeStatus>
            </activation>

            <credentials>
                <password>
                    <outbound/>
                </password>
            </credentials>

        </objectType>

    </schemaHandling>

</resource>
```

Die Test-Connection der Resource hat bei mir funktioniert:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23xL11e8xSX7SfSmarER564aS2Wg1qza5iQUHw5keVnw6iMcfvtF8Zvqap4Py6fSveaDV.png)

Danach bin ich auf einen der von HR importierten Usereinträge gegangen:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSz8K6VGkXRyNAzAF6x8U2RmQzdxAAd2r8Fn1349sS5ysmKbebrCmYmfycvPTXq5Y1h.png)
Dort klickte ich auf Assigenments und erstellte ein neues:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23twABpCt5zfQXsffSGfdwka7xGrikAfoSYkh8G4QsENmddEw6B5QnsLyJXZeD6XHdUzD.png)
Dort klickte ich auf Resource:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHbKgeGWEEZV8LT6tJFeSCYVR4gyVyjS8CwuESdaCLS8vVi9PBF1WLhSvfErapZU19F.png)
und fügte dort meine LDAP Reconcile Resource zu:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EoAh3TYw2jTZJoBD6SvRNWaNJ8tuQEg3ibP3bAypavTYJ1zsf7ERbJy2Wg3LnquBDTF.png)

Das Ganze musste natürlich gespeichert werden:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tcJEWQ6g3hfqP1z4h8z1KP3k8wACqaJaPcguptbsGKzUsFBk4A2SRAPL6GSdcfmW9Ln.png)

Damit wird sofort der LDAPadd Befehl im Hintergrund ausgelöst. Das Ergebnis kann mit 
> ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "dc=example,dc=com"

gesehen werden. Wir finden nun den HR User im LDAP wieder:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tRtD4FxzGZgquA1zNU2DiQNAaYqpaYqtMfvyMdnyKRkZ5zP3dAD25rxB4qKqQyq8akk.png)

Siehe auch: https://www.youtube.com/watch?v=882Xl2NYQDw

Das ist natürlich manuelle Arbeit, die für jeden User aus HR gemacht werden müsste. Das geht sicherlich auch automatisiert, ist aber hier nicht das Thema.

# Fazit
Wir sind nun in der Lage User aus HR im csv Format zu importieren und diese nach LDAP zu übertragen.
Als nächstes möchte ich eine rudimentäre Nginx-Applikation z.B. über OpenID Connect an den LDAP Server anbinden. Ziel ist, dass ein User, der mit der HR Datei geliefert wurde, sich an der Web-App anmelden kann.

So Stay tuned,

Achim Mertens










In dieser Dokumentation möchte ich zeigen, wie man eine Liste von Usern, die man z.B. von einer Human Resources (HR) Abteilung bekommt, in dem in dem open source Identity, Governance Administration (IGA) Server "Midpoint" importiert.

Ich habe im Vorfeld einen leeren Midpointserver via Podman bei mir lokal installiert (meine Dokumentation dazu siehe [hier](https://peakd.com/hive-139531/@achimmertens/installation-eines-midpoint-docker-containers)).

# Starten des Midpoint servers:
## Initial:
Wir wechseln in einer Linux- oder Windows Shell in das Midpoint Verzeichnis, welches [hier](https://github.com/Evolveum/midpoint-docker/tree/master) geholt werden kann.


Ich habe in der docker-compose.yml noch die Zeile
 > ./:/opt/midpoint/var/import:Z

hinzugefügt, damit man später einfacher Dateien austauschen und importieren kann:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGXhXRahBTvCFktrAQAPr3JK5ByY9AULiJfLQa9LhYTAYquzyZm9qTbUFHYZamv2pM8.png)

Wir starten den Server mit:
> podman compose up

Details dazu habe ich, wie oben schon erwähnt, [hier](https://peakd.com/hive-139531/@achimmertens/installation-eines-midpoint-docker-containers) beschrieben.

## Regelmäßiges Starten
Sobald der Server einmal eingerichtet wurde, liegt er als Podman Container vor und kann gestartet werden mit (in der Reihenfolge):

> podman start midpoint-midpoint_data-1
> 
> podman start midpoint-data_init-1
>
> podman start -a midpoint-midpoint_server-1

Gestoppt wird der Server in der Konsole mit STRG-x oder dem Löschen des Terminals in dem der Server läuft.

## Reset des Midpoint Servers
Man könnte nach der Installation auch die Container mit einem "podman compose up" neu erstellen und mit "podman compose down" löschen. Die Daten bleiben dabei erhalten, weil sie in einem Volume liegen. Dennoch ist es einfacher, die Container zu stoppen, anstatt sie immer zu löschen und neu anzulegen.

Wenn man die Daten aus Midpoint löschen/zurücksetzen will, geht das wie folgt:
> podman compose down
>
> podman volume rm midpoint_midpoint_data
>
> podman compose up


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo8KedTu6pANpf3r3wqUDf9e1cUbk6YSXHvhUFdmtQc7s6DxXZbBEPrXdS8VaCYDa8B.png)
Damit ist der Midpoint Server wieder jungfräulich.

# Anlegen eines Users in Midpoint
In einem Browser geben wir ein: http://localhost:8082/

Username: Administrator
Passwort: Test5ecr3t

Ich habe mir zunächst manuell einen User namens Achim angelegt. Dazu bin ich in der Adminoberfläche auf Benutzer gegangen und habe dort mit dem "+" Symbol einfach einen neuen User angelegt

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23w3AVLXt5aff9FNFgbtqKb25AvehnBiT1aZjAe5a2ymWphZBdo8W9humGyjXMm18KYkB.png)

# Import von Usern aus einer XML Datei

User brauchen ein Format. Da ich dieses erst mal nicht hatte und daher ein Import einer einfachen csv Datei nicht klappt, habe ich das Format über eine XML Datei mitgegeben:

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

# Import von Usern aus einer csv Datei
In der Realität kommen große Userdaten eher als csv (Comma Separated Value) Dateien daher.
Wie man diese importiert ist [hier](https://www.youtube.com/watch?v=HBYZpZ22fDo) in einem Youtube Video zu sehen (nicht zu hören). Im Folgenden habe ich dies nachgestellt:

Ich habe dazu von dieser Seite: https://github.com/Evolveum/midpoint-book/tree/master/samples/5
die Dateien hr.csv, resource-csv-hr.xml und task-hr-import.xml herunter geladen:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZXAPHSE6YBP365ta9xzFw5ZdQB8tSLeo8BeWzTVBUANQKgwcPPs8mr7cjJKtb9Zih.png)
Diese Dateien habe ich in das gemountete Verzeichnis /opt/midpoint/var/import gelegt.
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGXrbxNjJkgN232vzMAbn6fgj5jfTzyjRMhGjjevBgR7h8gfd2ennVf2AWdw3wfwisz.png)

Man kann auch, wenn im Podman Container die Mountoption nicht angegeben wurde, von Hand Dateien in den Container kopieren:
> podman cp hr.csv midpoint-midpoint_server-1:/opt/midpoint/var/import/hr.csv

Der Inhalt von hr.csv sieht wie folgt aus:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGXhUVqqoAJofaiiu2DamYArBnf49ZB1NJ7VZAWf8q67pozkMay9TBcA2rMGYc4eisu.png)

Die Resource und den Task habe ich als Objekt importiert (unter Resources/All Resources/Import bzw. Server Tasks/All Tasks/Import).
Ich musste den Pfad noch in der Resource unter Connector Configuration anpassen:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8D6MsrmvtwBCfd47XvfPdzedNcDDEnbY1NZBF4oULsDt7ws4aTJ9ncxCQ82k4osyaD.png)

Nun konnte ich den "HR System Import Task" laufen lassen:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZgM8nCqmPCZFkmNPMYy8wYnMetU7c3cQSmbPR2eE3xovNWRN5zhcUxuSCefNjHZf6.png)

Es wurden daraufhin Resourcen-Accounts erstellt und diese auch als User importiert:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8B2nvVpSMcB3wb2Hx1JSVYiMPrTxcd388rtiPG4vRudDzuirDu8QySvw2pGbFZJ5e8.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSwpGLB8fBE5pVq4GbnaPYztR8y2N7HzwSa5ghJQrjzxvvbeTbhf67qeYk5gos2kWvR.png)

Damit habe ich mein Etappenziel erreicht. Die User sind erfolgreich importiert (Juhuuu).

# Details
Man kann nun in dem Resourcenobject die Mappings und andere Einstellungen anpassen.
Zum Experimentieren empfehle ich, eine Kopie der Resource zu erstellen:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZPqFWPZQRstNRLXEPZ7QFe6ff4tVvDoQoD96CSiX6fgEwmdLCw4iK3PH7BHFnRkbb.png)

## Import Task
Dort kann man manuell einen neuen HR Import Task hinzufügen:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/245cf5ywwCLruKUskf8XY5p8iNY8jyRKAXDUeXmrUS3LoZ4bx6hwaS3js5Bh5Ng12H6XN.png)
Der Task wird wie folgt ausgefüllt:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSz8KRvCUakJwhmuXZxC62oE5zXLMxVzwNo4EQzuG24eG8hHgtUjCm9vh8Eken51Jxz.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tcNngg489U5oCrK5gxWKY6a2Jiyw5KUdtMSLYWJkjUJxvDxUV73RqSbb6KrTDx3oD15.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tmmEW2whBm39EEVRR2MkV2k3m4V7UnGuwGxUPwfHcNTvYWPyt3xZzhxKz93ARgB1bkj.png)

Das Ergebnis sieht man, wenn man in der csv Datei eine Person hinzufügt und diese dann auch importiert wird. Ich hatte "Axel Haar" noch hinzugefügt und er wurde erfolgreich importiert:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo6Ri48iQdu2sJk3CQQMuX3qJ1paQjEJahBdXV8QGgP58JrzXBY3FcAZZc7uhoHb1mp.png)

## CSV Import Resource
Ich habe versucht die von der Evolveum Demo Seite hochgeladene HR Import Resource von Hand nachzubauen. Leider hat das nach vielen Versuchen nicht geklappt. Irgendetwas scheint in der XML-Datei die ich importiere (resource-csv-hr.xml), versteckt zu sein, was sich über die graphische Oberfläche nicht einbauen lässt. Das sieht man auch, wenn man dort in die Basic Attributes des Account Objekts klickt. Dort wird angemeckert, dass das Feld "Kind" ein Mussfeld ist, aber nichts drin steht (Bild dazu siehe unten).
Bei meinem nachgebautem HR Import Resource Objekt werden die Daten zwar importiert, aber sie erscheinen nur als Resourcenaccounts und nicht als User.
Nichtsdestoweniger möchte ich hier ein paar Screenshots des originalen, importierten Resourcenobjekts zeigen:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZ9tkfKV6TH4iZLtBCMBryVHuV6ZuZvZcGAQedFTsNGBZPnfEiPZYtrVtvF3uviLNF.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23wrAEXr3tRmdqGfUV3sDLVKu3w4tiGanyxCG5z8gqQWsCT6e8tz6t9Gg7gDGasuSW5PN.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23sxon1fgCi3ByxC2zkfPnyineimwpz8aburUor8coapetV3ZJ7b641Juw9eaYCPcTeSN.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSz8J2vo31yREXfYiS9ztVXqJmrzQMkWuYndUvCAitoTpZFLiv7ftZNtBV5Kow5QXh3.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo2BSgYeWqHyJdNFRziXNfjokCuMZyBEPtuGSqYfeFvKeBBpwh8eguhxGcUKZHJeWB3.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo2BJ5b2aWXJCwA7HhHzd8KvpdpR1DnqgXQ47SPxrFZY3JeTFHGrtd2hPPn7QbRgTTJ.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHb6kpjALDMk8JeNrzrgu67hDM2gMpw1c1APgShuFfbc2ToNXPPRNG1eFEdQoeKm2Eq.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHbTwrPzd6btkmnVYhzce2PRqebHM6dgFKecSn186bU9ZvKmRk6PHuM1PwsYWxxovUG.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tmmEV5SmMyEwgr15Zyjh14MyZuw5WTNkG9kJ18oRqaPwShnNK1NNPEwoDSz3MK3a8Sw.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSyuksniPsjVydioTBYCiZjnAuVjCzsj1BPqEB1Gb2tqULpFQhZNuR6fCzrmMqDPVKo.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHbP7XK99yv2uyZ1AbG5KC75nWCEgc8YS61mZhmhg4NhzMfVrrTpgtdvYqhF71AEZGy.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23uFwMHi3b9Z3QyLp9QkDkuCwLWKrgNL5QWyEq8ruoGFGeKG5dXCPzJqUgr1WTuCtPEEU.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CijwoHo3Z5Bnx1HU6v8rYNmhZ3kQvHen3BtRSuxntnTkAkZ4Mo9Hr8Yh2yKeZefih.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSzLNvvdmfWLm7wGGGs3LpBXkUGyRkQtpn2Gn55Mv4mhRc4wcYLWY5QeSAkRwcJhiDy.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo6SDzz5Se92R3PoRQ6NL8NiBWNhqfnSTh1kmqNFJiXsYbMaEZreCF1VBSi9n6iJSEe.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo6Rmyxg3pPJi6XkGp8aAHauEE96KKsJLqqZ1JUvtZYby4pEe1MeffpZ6GiQiVnziVd.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23sxon1fhdwgHpeVNbSPZVErdysnvCn9Lavk6azWtpqnRJb8J2VDGRfG835m9JJdabNNH.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHbYKtrUPKHofgkQS8fssKDj7Bmf83jpNN4hy2sRoe1hZ5tCzmpZWe9ii7vGUGTLj5o.png)

# Fazit
Mit dem oben gebauten Konstrukt haben wir einen einfachen, funktionierenden IGA Server, der größere Mengen von Userdaten importieren kann. Diese können nun aufbereitet (z.B. für Logins oder mit Rechten verknüpft werden) und weiter gereicht werden.
Als nächstes möchte ich diese User an einen LDAP Server exportieren. 
So, stay tuned!

Achim Mertens



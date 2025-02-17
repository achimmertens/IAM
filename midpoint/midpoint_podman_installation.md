Hallo zusammen,

ich soll für meine neue Arbeitsstelle einen "Identity and Access Management" (IAM) System installieren. Das braucht man um in einer Firma zentral die Benutzer zu verwalten. Damit braucht nicht jedes firmeninterne System zu administrieren wen es gibt und was der jeweilige User darf. Für den Benutzer springt im Idealfall heraus, dass er sich morgens einmal authentifiziert und dann ohne weitere Passwörter auf alles zugreifen kann, was er braucht.
![](https://www.kiteworks.com/wp-content/uploads/2022/09/Identity-and-Access-Management.webp)
*[Quelle](https://www.kiteworks.com/wp-content/uploads/2022/09/Identity-and-Access-Management.webp)*

Ein solches Werkzeug ist das Open Source Tool "Midpoint", welches (u.a.) von [Evolveum](https://evolveum.com/) supportet wird.

Mein Ziel hier war es, dass Tool einmal lokal bei mir mit einem Docker Container zum Laufen zu bringen. 

# Die Installation von Midpoint
Nach ein paar Fehlversuchen stieß ich auf folgendes Video:
https://www.youtube.com/watch?v=XJXYKG7EXVg

Ich habe die Angaben aus dem Video befolgt:
- Download von docker-compose.yml aus https://github.com/Evolveum/midpoint-docker/blob/master/docker-compose.yml
- Docker Terminal gestartet
- Dort in das Verzeichnis gewechselt, wo die docker-compose.yml liegt
- Folgenden Befehl eingegeben:
>$ docker compose up
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23sxp4JY4pnREewU5nQ988uJcjtL2Vq4LLVEgX4KRCBddBpC3yz9RtFZ8AbPdXtuudDBX.png)
Nach ca. 2 Minuten war es fertig.
Tadaaaaa! Der Server ist gestartet und ich konnte darauf zugreifen:

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23ynmnuHMEo8XaCX5jfrhaaxsevtiakhCYYZaiJPkzgqz2p1ZbzvzFx5SMkYbotwHPdYt.png)
Einloggen mit:
Administrator
Test5ecr3t
(Siehe Zeile 75 in der docker-compose.yml)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tmhJWmZ4JhggnxcEW5qWCo9UA5fgV47zGSZPpw3vpSGMRcJ4V2cGnXo8pys9W2wo7qB.png)

# Stoppen des Servers:
- In der Shell STRG+C eingeben um den Docker Container zu stoppen
- Um den Container und die Volumes komplett zu löschen:
> $ docker compose down -v

# Wie geht es weiter?
Nun kann ich mit der Plattform etwas spielen. Das kann man zwar auch [online](https://demo.evolveum.com/midpoint/login?0), aber lokal habe ich mehr Möglichkeiten.
Ich könnte mir sogar vorstellen, eine kleine Applikation zu basteln (z.B. Eine Webseite mit einem Knopf, der Hive verschickt, wenn man vorher Werbung gelesen hat), die an das Midpoint angeschlossen wird. Aber schaun wir mal. Das erste Etappenziel ist zumindest erreicht.

Gruß, Achim


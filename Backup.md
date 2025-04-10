# Backup und Restore einer PostgreSQL Datenbank im Midpoint Container

In dieser Dokumentation beschreibe ich, wie ich die Daten, die in einer Applikation, die in einem Podman Container läuft, sichere und nach einem Totalverlust wieder herstelle.
Ich verwende in meinem Beispiel einen Midpoint Container, in dem als Datensatz User erstellt wurden. Ich mache ein Backup, zerstöre alle Container und Volumes und anschließend zaubere ich den Zustand der letzten Sicherung wieder her.
Dies ist Teil eines größeren Projektes, wo ich versuche ein komplettes IAM System aufzubauen:



![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23x1Yjig6GYfsvo8nBWrkvwnXtrqPcmHKM1SsZMJAVrdzMimtX1hfYn9TJdWZPQgck9ES.png)
Ich habe im Vorfeld folgendes dokumentiert:
1. Installation eines leeren Midpointservers (IGA) via Podman  (siehe [Punkt 1](https://peakd.com/hive-139531/@achimmertens/installation-eines-midpoint-docker-containers))
2. Installation eines LDAP Podman Servers (siehe [Punkt 2](https://peakd.com/hive-121566/@achimmertens/installation-eines-ldap-servers-via-podman-image))
3. Installation eines Keyclock Podman Servers (siehe [Punkt 3](https://peakd.com/hive-121566/@achimmertens/keycloak-eine-software-die-den-zugriff-regelt))
4.  Ein hr.csv Import in den Midpoint Server (siehe [Punkt 4](https://peakd.com/hive-121566/@achimmertens/wie-man-eine-hrcsv-user-datei-in-dem-iga-server-midpoint-importiert))
5.  User Export von Midpoint nach LDAP (siehe [Punkt 5](https://peakd.com/hive-121566/@achimmertens/wie-man-mit-dem-iga-server-midpoint-hr-user-nach-ldap-exportiert))

Ich halte diese Dokumentation allgemein und so kann sie auch für andere Projekte verwendet werden.

Inhalt:
- [Backup und Restore einer PostgreSQL Datenbank im Midpoint Container](#backup-und-restore-einer-postgresql-datenbank-im-midpoint-container)
- [Viele Wege führen nach Rom (oder auch nicht)](#viele-wege-führen-nach-rom-oder-auch-nicht)
  - [1. Ex- und Import von Containern als Tar-Archive](#1-ex--und-import-von-containern-als-tar-archive)
  - [2. Exportieren des Volumes als ein tar-Archiv.](#2-exportieren-des-volumes-als-ein-tar-archiv)
  - [3. Sichern des Volumes im Betriebssystem](#3-sichern-des-volumes-im-betriebssystem)
  - [4. Sichern mit pg\_dump](#4-sichern-mit-pg_dump)
    - [Tipp: SQL Zugriff im laufenden Betrieb](#tipp-sql-zugriff-im-laufenden-betrieb)
- [Sicherung und Restore via Dockerfile](#sicherung-und-restore-via-dockerfile)
  - [Backup erstellen](#backup-erstellen)
  - [Restore](#restore)
- [Komplette docker-compose.yml](#komplette-docker-composeyml)
- [Fazit](#fazit)


# Viele Wege führen nach Rom (oder auch nicht)
Es gibt nicht nur viele Wege die nach Rom führen, sondern auch viele Wege wie man Backups erstellen kann von einer SQL-Datenbank, die innerhalb eines Podman/Docker Containers läuft.
Das Backup ist auch nicht so sehr das Problem, wie nachher das Restore.
Einige Wege deute ich hier an, einen beschreibe ich ausführlich. Wer also meine Fehlversuche und Erfahrungen überspringen möchte, kann direkt zu Punkt 5 vorrücken:
1. Ex- und  Import von Containern als tar-Archive.
2. Exportieren des Volumes als ein Tar-Archive.
3. Sichern des Volumes im Betriebssystem
4. Sichern mit Pg_dump
5. Sicherung und Restore via Dockerfile


## 1. Ex- und Import von Containern als Tar-Archive
Folgende Befehle schreiben den Inhalt der Container in Tar-Archive:

> podman container export -o /d/IAM/backups/midpoint_container_backup.tar midpoint-midpoint_server-1
podman container export -o /d/IAM/backups/midpoint_container_backup.tar midpoint-midpoint_data-1

Folgendes Beispiel importiert eines der Archive in einen Container:

> podman import /d/IAM/backups/midpoint_container_backup.tar midpoint-restored-image

Es werden aber nur die Container gesichert, nicht die Volumes.


## 2. Exportieren des Volumes als ein tar-Archiv.
Sinnvoller ist es natürlich die Volumes zu sichern, weil ja da die Daten liegen.
Zuerst sollten wir unsere Volumes kennen. Wir sehen sie mit:
> podman volume ls

Wenn wir mehr über ein jeweiliges Volume erfahren wollen geben wir ein:
> podman volume inspect midpoint_midpoint_home | grep Mountpoint        

Als Ergebnis sehen wir z.B.:

> "Mountpoint": "/home/user/.local/share/containers/storage/volumes/midpoint_midpoint_home/_data"


Der Befehl zum Sichern lautet generell:
> podman volume export <volumename> --output /path/to/backup/volumename.tar

Und somit in meinem Beispiel:
> podman volume export midpoint-midpoint_data-1 --output /d/IAM/backups/midpoint_data_backup.tar

Das Problem bei mir war aber, dass es nicht funktioniert :-( 
Ich erhalte eine Fehlermeldung, dass der Befehl falsch geschrieben ist und der angegebene Pfad nicht existiert. Damit geht auch folgendes bei mir nicht:

## 3. Sichern des Volumes im Betriebssystem
Podman und Docker sind ja Programme, die auf einem Rechner laufen und selber Daten speichern. Laut dem "podman volume inspect" Befehl, liegt das Volume im Betriebssystem, bei mir unter: D:/Users/User/anaconda3/Library/d/IAM/midpoint.
Ich habe es aber weder da noch woanders auf meinem Windows Rechner gefunden. Hätte ich es dort gesehen, könnte man es kopieren und wegsichern (bei gestoppten Containern).

## 4. Sichern mit pg_dump
Eigentlich wollen wir ja nur ein paar SQL Daten sichern. Das geht mit folgendem Befehl:
```
podman exec -i midpoint-midpoint_data-1 pg_dump \
  -U midpoint \
  -h localhost \
  -d midpoint \
  -W > /d/IAM/backups/midpoint_backup_$(date +%Y%m%d).sql
```

Das Wiedereinspielen geht wie folgt:
```
PGPASSWORD=db.secret.pw.007 cat /d/IAM/backups/midpoint_backup_20250321.sql | \
  podman exec -i midpoint-midpoint_data-1 psql -U midpoint -d midpoint
```

Bei mir fehlte danach noch das Admin Passwort, das liegt aber nicht an der SQL-DB, sondern am fehlenden keystore.jceks, den ich bei diesem Versuch noch nicht gesichert hatte (mehr dazu siehe unten). D.h. damit sollte es eigentlich funktionieren.

### Tipp: SQL Zugriff im laufenden Betrieb
Hier noch ein Tipp, wie man im laufenden Container auf die SQL Datenbank zugreift:
- Anmelden am SQL Server:

      PGPASSWORD=db.secret.pw.007 podman exec -it   midpoint-midpoint_data-1 \
      psql -U midpoint -d midpoint

- Anzeigen aller Tabellen:

      \dt

  ![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGXZimDcwcFs18XRviWk4bHnYPNh8Mmh9yua5x6ENMht17ciYSLuwnUnVLEvHm4qMHR.png)

- SQL Abfrage:
  
      SELECT * FROM m_user WHERE nameorig = 'administrator';

# Sicherung und Restore via Dockerfile

Dieser Weg ist meines Achtens der sauberste und vor allem: Er funktioniert bei mir.
Wir bauen hier die Option eines Restores direkt in die Containerstruktur mit ein.
Dazu müssen wir die originale Datei [docker-compose.yml ](https://github.com/Evolveum/midpoint-docker/blob/master/docker-compose.yml) um folgende Punkte erweitern:
Sowohl in der midpoint_server als auch in der midpoint_data Service-Section muss ein zusätzliches Volume eingefügt werden:  
Bei midpoint_data:
   
    - ./:/backup:Z
  
Bei midpoint_server:

    - ./:/opt/midpoint/var/import:Z

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGW1di7ViSQES3G1JFSw26tyqqQiPitq2QGHTPcpMtLrvdLsPzYFRNnLJUjvkPtzYTB.png)

Dieses Volume zeigt auf den Ordner, wo die docker-compose.yml liegt und bindet es als Laufwerk in den jeweiligen Container ein. Dadurch kann innerhalb des Container auf die Festplatte des Betriebssystems, auf dem Podman läuft, zugegriffen werden.

Nun fügen wir einen weiteren Service in die docker-compose.yml ein:

```
  midpoint_restore:
    image: evolveum/midpoint:${MP_VER:-latest}-alpine
    command: 
      - /bin/bash
      - -c
      - |
        echo 'Restoring database...'
        # Restore PostgreSQL data
        cp -r /backup/midpoint_data_backup/* /var/lib/postgresql/data/
        chown -R 999:999 /var/lib/postgresql/data/
        chmod -R 700 /var/lib/postgresql/data/
        
        echo 'Restoring keystore file...'
        # Restore keystore file
        if [ -f /backup/keystore.jceks.backup ]; then
          cp /backup/keystore.jceks.backup /opt/midpoint/var/keystore.jceks
          chmod 600 /opt/midpoint/var/keystore.jceks
          echo 'Keystore file restored successfully.'
        else
          echo 'WARNING: Keystore backup file not found!'
        fi
        
        echo 'Restore completed.'
    depends_on:
      - midpoint_data
    volumes:
      - midpoint_data:/var/lib/postgresql/data
      - midpoint_home:/opt/midpoint/var
      - ./:/backup:Z
    networks:
      - net
    profiles:
      - restore
```

Dieser Container startet im Normalfall ("podman compose up") NICHT. Das wird durch den untersten Abschnitt "profiles" geregelt. Auch dieser Container besitzt ein gemountetes Laufwerk "backup", wo er auf die gesicherten Daten des darunter liegenden Betriebssystems zugreifen kann.
Und das tut er auch mit den Copy-Befehlen in der Kommandozeile innerhalb des Containers.

## Backup erstellen
Das Backup kann damit jederzeit wie folgt erzeugt werden:
Die Container müssen oben sein, aber es sollte kein Traffic, bzw. Datenänderung stattfinden.

Folgende Befehle erzeugen dann sowohl ein Backup der Datenbank als auch eines des Keystores (den brauchen wir für das Admin Passwort):

> podman cp -a midpoint-midpoint_data-1:/var/lib/postgresql/data ./midpoint_data_backup
> 
> podman cp -a midpoint-midpoint_server-1:/opt/midpoint/var/keystore.jceks ./keystore.jceks.backup

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGXzGyFPVgZfqe8xVu7opK9j62T9yeCef9q6Znpoz7SFgZtwZXvi3P7xRoWKbYRDpLF.png)

## Restore
Ich habe danach meine Container und meine Volumes komplett gelöscht.
Dann habe ich sie wieder initialisiert. ([Details](https://peakd.com/hive-121566/@achimmertens/wie-man-eine-hrcsv-user-datei-in-dem-iga-server-midpoint-importiert) <- Reset des Midpoint Servers).
Dann habe ich in einer Konsole folgende Befehle nacheinander ausgeführt:
```
podman stop midpoint-midpoint_server-1
podman stop midpoint-midpoint_data-1
podman compose up midpoint_restore
podman compose up
```
Und Tadaaa, meine Daten innerhalb meines Midpointservers waren wieder da :-D

Hier seht Ihr die:







# Komplette docker-compose.yml

```
version: "3.3"

services:
  midpoint_data:
    image: postgres:16-alpine
    environment:
     - POSTGRES_PASSWORD=db.secret.pw.007
     - POSTGRES_USER=midpoint
     - POSTGRES_INITDB_ARGS=--lc-collate=en_US.utf8 --lc-ctype=en_US.utf8
    networks:
     - net
    volumes:
     - midpoint_data:/var/lib/postgresql/data
     - ./:/backup:Z

  data_init:
    image: evolveum/midpoint:${MP_VER:-latest}-alpine
    command: >
      bash -c "
      cd /opt/midpoint ;
      bin/midpoint.sh init-native ;
      echo ' - - - - - - ' ;
      bin/ninja.sh -B info >/dev/null 2>/tmp/ninja.log ;
      grep -q \"ERROR\" /tmp/ninja.log && (
      bin/ninja.sh run-sql --create --mode REPOSITORY  ;
      bin/ninja.sh run-sql --create --mode AUDIT
      ) ||
      echo -e '\\n Repository init is not needed...' ;
      "
    depends_on:
     - midpoint_data
    environment:
     - MP_SET_midpoint_repository_jdbcUsername=midpoint
     - MP_SET_midpoint_repository_jdbcPassword=db.secret.pw.007
     - MP_SET_midpoint_repository_jdbcUrl=jdbc:postgresql://midpoint_data:5432/midpoint
     - MP_SET_midpoint_repository_database=postgresql
     - MP_INIT_CFG=/opt/midpoint/var
    networks:
     - net
    volumes:
     - midpoint_home:/opt/midpoint/var

  midpoint_server:
    image: evolveum/midpoint:${MP_VER:-latest}-alpine
    depends_on:
      data_init:
        condition: service_completed_successfully
      midpoint_data:
        condition: service_started
    command: [ "/opt/midpoint/bin/midpoint.sh", "container" ]
    ports:
      - 8082:8080
    environment:
     - MP_SET_midpoint_repository_jdbcUsername=midpoint
     - MP_SET_midpoint_repository_jdbcPassword=db.secret.pw.007
     - MP_SET_midpoint_repository_jdbcUrl=jdbc:postgresql://midpoint_data:5432/midpoint
     - MP_SET_midpoint_repository_database=postgresql
     - MP_SET_midpoint_administrator_initialPassword=Test5ecr3t
     - MP_UNSET_midpoint_repository_hibernateHbm2ddl=1
     - MP_NO_ENV_COMPAT=1
    networks:
     - net
    volumes:
     - midpoint_home:/opt/midpoint/var
     - ./:/opt/midpoint/var/import:Z

  midpoint_restore:
    image: evolveum/midpoint:${MP_VER:-latest}-alpine
    command: 
      - /bin/bash
      - -c
      - |
        echo 'Restoring database...'
        # Restore PostgreSQL data
        cp -r /backup/midpoint_data_backup/* /var/lib/postgresql/data/
        chown -R 999:999 /var/lib/postgresql/data/
        chmod -R 700 /var/lib/postgresql/data/
        
        echo 'Restoring keystore file...'
        # Restore keystore file
        if [ -f /backup/keystore.jceks.backup ]; then
          cp /backup/keystore.jceks.backup /opt/midpoint/var/keystore.jceks
          chmod 600 /opt/midpoint/var/keystore.jceks
          echo 'Keystore file restored successfully.'
        else
          echo 'WARNING: Keystore backup file not found!'
        fi
        
        echo 'Restore completed.'
    depends_on:
      - midpoint_data
    volumes:
      - midpoint_data:/var/lib/postgresql/data
      - midpoint_home:/opt/midpoint/var
      - ./:/backup:Z
    networks:
      - net
    profiles:
      - restore

networks:
  net:
    driver: bridge

volumes:
  midpoint_data:
  midpoint_home:
```
# Fazit
Nun bin ich in der Lage beliebige Daten, die in Containern und Volumes erzeigt werden, zu sichern und wieder herzustellen.
Als Nächstes möchte ich einen Nginx Server an einen LDAP Server anbinden.
So, stay tuned,

Achim Mertens

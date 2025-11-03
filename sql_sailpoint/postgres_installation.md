<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Anforderung
Ich habe ein postgres podman Image herunter geladen. Ich möchte nun einen Container erstellen, der dauerhaft die IP-Adresse 10.89.0.20 haben soll, den Namen SQL_Sailpoint tragen soll, in dem Netzwerk "sailpoint_net" laufen soll. Dieses Netzwerk gibt es noch nicht und soll erstellt werden.

Ich halte es für sinnvoll, den Container über eine docker-compose.yml Datei zu erstellen. Wie sieht die Datei aus und wie erzeuge ich damit den Container?
Wie kann ich auf den SQL-Server, nachdem der Container gestartet ist, zugreifen? Wie lautet das Passwort und der User? Wie sieht der Befehl aus um die initial vorhandenen Tabellen zu sehen?

# Antwort
Um einen PostgreSQL-Container mit Podman anhand einer docker-compose.yml-Datei zu erstellen, der folgende Anforderungen erfüllt:

- Feste IP-Adresse: 10.89.0.20
- Containername: SQL_Sailpoint
- Netzwerk: sailpoint_net (noch zu erstellen, mit Subnetz 10.89.0.0/24)


# 1. docker-compose.yml Beispiel

```yaml
version: "3.7"

services:
  sql_sailpoint:
    image: postgres:latest  # Passe ggf. auf deinen Image-Namen an
    container_name: SQL_Sailpoint
    networks:
      sailpoint_net:
        ipv4_address: 10.89.0.20
    environment:
      POSTGRES_USER: sailpoint
      POSTGRES_PASSWORD: supersecurepass
      POSTGRES_DB: sailpoint_db
    ports:
      - "5432:5432" # Damit du von außen zugreifen kannst

networks:
  sailpoint_net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.89.0.0/24
```

Mit dieser Datei wird das Netzwerk sailpoint_net automatisch erstellt, wenn du podman-compose oder docker-compose verwendest.[^1_1][^1_2][^1_3]

# 2. Container erzeugen

Speichere die Datei als `docker-compose.yml` und starte den Container im selben Verzeichnis mit:

```bash
podman-compose up -d
```

(falls du docker-compose nutzt: `docker-compose up -d`)

Dadurch wird das Netzwerk erstellt und der Container mit der Adresse 10.89.0.20 gestartet.[^1_2][^1_3][^1_1]

# 3. Zugriff auf den PostgreSQL-Server

- Host: 10.89.0.20 (innerhalb deines Containers/Subnetzes)
- Port: 5432 (Standard)
- Benutzer: sailpoint (wie in der compose-Datei angegeben)
- Passwort: supersecurepass (wie in der compose-Datei angegeben)
- Datenbank: sailpoint_db

Du kannst dich lokal verbinden mit:

```bash
podman exec -it SQL_Sailpoint psql -U sailpoint -d sailpoint_db
```

Um von außen (auf dem Host), sofern du den Port weitergeleitet hast:

```bash
psql -h localhost -U sailpoint -d sailpoint_db -p 5432
```

Passe ggf. Host/IP an je nach Netzwerkeinrichtung.

# 4. Initiale Tabellen anzeigen

Sobald du im psql-Prompt bist, gib ein:

```sql
\dt
```

Das listet alle vorhandenen Tabellen im aktuellen Schema.[^1_4][^1_5][^1_6][^1_7]

# Hinweise zu den Zugangsdaten

Standardmäßig setzen offizielle Postgres-Images KEIN Passwort für den Benutzer postgres, außer du definierst es über die Umgebungsvariable POSTGRES_PASSWORD oder POSTGRES_USER beim Start des Containers. Das ist in obigem YAML bereits enthalten, sodass direkt nutzbare Zugangsdaten generiert werden.[^1_8][^1_9][^1_10][^1_11]

# Zusammenfassung

- Lege die docker-compose.yml mit den Vorgaben an.
- Starte den Container mit podman-compose up -d.
- Greife per psql und den gesetzten Zugangsdaten auf die Datenbank zu.
- Tabellensicht mit \dt im psql-Client.

Solltest du noch weitere Fragen zur Einrichtung oder Nutzung haben, stehe ich gerne zur Verfügung!

<div style="text-align: center">⁂</div>

[^1_1]: https://www.baeldung.com/ops/docker-assign-static-ip-container

[^1_2]: https://www.reddit.com/r/portainer/comments/zp2lyr/how_do_i_add_a_static_ip_to_my_docker_in_a_docker/

[^1_3]: https://mklasen.com/set-a-static-ip-for-docker-compose-containers/

[^1_4]: https://www.dbvis.com/thetable/how-to-list-tables-in-postgres-complete-guide/

[^1_5]: https://www.bytebase.com/reference/postgres/how-to/how-to-list-tables-postgres/

[^1_6]: https://tembo.io/docs/getting-started/postgres_guides/how-to-show-tables-in-postgres

[^1_7]: https://dbschema.com/blog/postgresql/show-tables/

[^1_8]: https://www.atlassian.com/data/admin/how-to-set-the-default-user-password-in-postgresql

[^1_9]: https://www.bytebase.com/reference/postgres/how-to/postgres-default-password/

[^1_10]: https://www.reddit.com/r/docker/comments/1c538se/how_to_change_the_postgresql_password_within/

[^1_11]: https://stackoverflow.com/questions/40599116/where-is-the-postgres-username-password-being-created-in-this-dockerfile

[^1_12]: https://github.com/containers/podman-compose/issues/720

[^1_13]: https://forums.docker.com/t/docker-compose-static-ip-container-linux-to-mac/42513

[^1_14]: https://github.com/containers/podman/issues/11493

[^1_15]: https://docs.podman.io/en/stable/markdown/podman-network.1.html

[^1_16]: https://docs.podman.io/en/v5.0.3/markdown/podman-network-create.1.html

[^1_17]: https://stackoverflow.com/questions/76548172/unable-to-create-podman-network-due-to-no-free-subnet-pools

[^1_18]: https://github.com/containers/podman/issues/21086

[^1_19]: https://stackoverflow.com/questions/39493490/provide-static-ip-to-docker-containers-via-docker-compose

[^1_20]: https://www.reddit.com/r/podman/comments/1isbryk/podman_network_static_subnets/


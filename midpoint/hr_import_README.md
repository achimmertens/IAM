- Starte den psql Server
- kopiere die Dateien in den psql Container:    
    - init_hr_table.sql
    - import_hr-csv.sql
    > podman cp init_hr_table.sql midpoint-midpoint_data-1:/tmp
    > podman cp import_hr-csv.sql midpoint-midpoint_data-1:/tmp
    > podman cp hr.csv midpoint-midpoint_data-1:/tmp

- Führe die Befehle innerhalb des Containers aus:
>podman exec -it midpoint-midpoint_data-1 bash
> psql -h 10.89.0.13 -U midpoint -d postgres
(POSTGRES_PASSWORD=db.secret.pw.007)
> \i /tmp/init_hr_table.sql
> \i /tmp/import_hr-csv.sql

Ergebnisse überprüfen mit:
\dt
\d hr
SELECT * FROM hr;
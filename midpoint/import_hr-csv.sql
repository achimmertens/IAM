COPY hr(id,emailadresse, loginname, vorname, nachname, geschlecht)
FROM '/tmp/hr.csv' DELIMITER ',' CSV HEADER;
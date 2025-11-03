CREATE TABLE IF NOT EXISTS hr (
       id SERIAL PRIMARY KEY,
       emailadresse VARCHAR(255),
       loginname VARCHAR(100),
       vorname VARCHAR(100),
       nachname VARCHAR(100),
       geschlecht VARCHAR(10)
);
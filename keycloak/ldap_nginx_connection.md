Hallo zusammen,

ich soll für einen Kunden ein Identity und Account Management System in Betrieb nehmen. Da das Ganze in der Firmenumgebung kompliziert genug ist, teste ich es vorher bei mir lokal aus. Jetzt habe ich einen Durchbruch erzielt.


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23x1YcPD68Y7aduQ5aYP9sRcpKXJfF5CNraMSxEPwqnbShKgpmjHoXg6MtBxbfjqtdHH6.png)


Ich habe im Vorfeld schon folgendes dokumentiert:
1. Installation eines leeren Midpointservers (IGA) via Podman  (siehe [Stufe 1](https://peakd.com/hive-139531/@achimmertens/installation-eines-midpoint-docker-containers))
2. Installation eines LDAP Podman Servers (siehe [Stufe 2](https://peakd.com/hive-121566/@achimmertens/installation-eines-ldap-servers-via-podman-image))
3. Installation eines Keyclock Podman Servers (siehe [Stufe 3](https://peakd.com/hive-121566/@achimmertens/keycloak-eine-software-die-den-zugriff-regelt))
4.  Ein hr.csv Import in den Midpoint Server (siehe [Stufe 4](https://peakd.com/hive-121566/@achimmertens/wie-man-eine-hrcsv-user-datei-in-dem-iga-server-midpoint-importiert))
5.  User Export von Midpoint nach LDAP (siehe [Stufe 5](https://peakd.com/hive-121566/@achimmertens/wie-man-mit-dem-iga-server-midpoint-hr-user-nach-ldap-exportiert))
6. Backup & Restore (siehe [Stufe 6](https://peakd.com/hive-121566/@achimmertens/backup-und-restore-einer-postgresql-datenbank-im-midpoint-container))


Diese Dokumentation (Stufe 7 + 8) beschreibt die vollständige Integration eines Identity and Access Management (IAM) Stacks bestehend aus MidPoint, LDAP, Keycloak und Nginx mit dem Schwerpunkt auf die beiden letzten Server, die bisher noch fehlten. Dieser gesamte Stack ermöglicht hiermit:

1. Benutzer-Management in MidPoint (Zusammenfassung)
2. Synchronisation der Benutzer mit LDAP (Zusammenfassung)
3. SSO-Authentifizierung über Keycloak
4. Geschützte Webseiten mit Nginx

Inhalt:


- [1. Systemarchitektur \& Netzwerk-Setup](#1-systemarchitektur--netzwerk-setup)
  - [1.1 Komponenten](#11-komponenten)
  - [1.2 Netzwerk-Setup](#12-netzwerk-setup)
- [2. MidPoint Setup und LDAP-Integration](#2-midpoint-setup-und-ldap-integration)
  - [2.1 MidPoint Container starten](#21-midpoint-container-starten)
  - [2.2 LDAP Resource in MidPoint konfigurieren](#22-ldap-resource-in-midpoint-konfigurieren)
  - [2.3 Benutzer von MidPoint nach LDAP synchronisieren](#23-benutzer-von-midpoint-nach-ldap-synchronisieren)
- [3. LDAP-Server Setup](#3-ldap-server-setup)
  - [3.1 Container starten](#31-container-starten)
  - [3.2 LDAP-Benutzer anlegen](#32-ldap-benutzer-anlegen)
- [3. Keycloak Setup](#3-keycloak-setup)
  - [3.1 Container starten](#31-container-starten-1)
  - [3.2 LDAP-Integration in Keycloak einrichten](#32-ldap-integration-in-keycloak-einrichten)
  - [3.3 Client für Nginx erstellen](#33-client-für-nginx-erstellen)
- [4. Nginx Setup](#4-nginx-setup)
  - [4.1 Nginx Konfiguration](#41-nginx-konfiguration)
    - [Erstellen Sie die Datei `default.conf`:](#erstellen-sie-die-datei-defaultconf)
    - [nginx.conf](#nginxconf)
  - [4.2 Container starten](#42-container-starten)
- [5. Testing](#5-testing)
- [6. Fehlersuche und Debugging](#6-fehlersuche-und-debugging)
  - [LDAP-Verbindung testen](#ldap-verbindung-testen)
  - [LDAP-IP ermitteln](#ldap-ip-ermitteln)
  - [Nginx-Logs anzeigen](#nginx-logs-anzeigen)
  - [Keycloak-Logs anzeigen](#keycloak-logs-anzeigen)
  - [Container-Status überprüfen](#container-status-überprüfen)
  - [Netzwerk-Debugging](#netzwerk-debugging)
  - [Häufige Probleme und Lösungen](#häufige-probleme-und-lösungen)
- [7. Fazit](#Fazit)


## 1. Systemarchitektur & Netzwerk-Setup

### 1.1 Komponenten
Das System besteht aus vier Hauptkomponenten, die alle in separaten Podman-Containern laufen:
1. MidPoint: Identity Management System
2. LDAP-Server (389ds): Verwaltet Benutzerkonten
3. Keycloak-Server: Handhabt die Authentifizierung
4. Nginx-Server: Stellt die geschützte Webseite bereit


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGVGGcKpb5f13a8kGnCoVJzsYmZpjyh3A61Kjm14XxU8KtgB1nE97ZJqsuEnQSpqHMX.png)
*Alle beteiligten Podman Container*


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EoH4e71EumyDdHH61dv9gcCMgbhTPAzHewKfuJf8LMeYYKwZqFtu8riCSuf2ZP3WRz7.png)
*Screenshot aller vier aktiven Komponenten*
### 1.2 Netzwerk-Setup
```bash
# Prüfen Sie zuerst, ob bereits Netzwerke existieren
podman network ls

# Erstellen Sie ein neues Netzwerk für die Container
podman network create midpoint_net

# Überprüfen Sie die Netzwerkkonfiguration
podman network inspect midpoint_net

# Nützliche Befehle für die Netzwerkdiagnose
# Alle Container und ihre IPs anzeigen
podman inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(podman ps -q)

# Netzwerkverbindungen zwischen Containern testen
(Das Klappt nur, wenn ping im Container installiert ist, was bei uns nicht der Fall ist.)
podman exec -it nginx_server ping keycloak_server
podman exec -it keycloak_server ping ldap_server
```

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGVdSFSEqkExaLw1HtxUhuoV5yCXzUwfJHYPLhK58UvLDcCmQKYXzPXvfzQJk4owcqf.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tRtNAe7kcp66BmZhhnRvmXPyGhj5bHyZDE1br5o1ZKsAc2i2uxh6VjAwnKTHrKw4qwH.png)


## 2. MidPoint Setup und LDAP-Integration

### 2.1 MidPoint Container starten
```bash
# podman compose up
podman start midpoint-midpoint_data-1
podman start midpoint-data_init-1
podman start -a midpoint-midpoint_server-1
```

### 2.2 LDAP Resource in MidPoint konfigurieren
1. Öffnen Sie http://localhost:8080/midpoint
2. Loggen Sie sich als Administrator ein (administrator/Test5ecr3t)
3. Gehen Sie zu Configuration → Resources
4. Erstellen Sie eine neue Resource:
   - Name: LDAP-Server
   - Type: LDAP Server
   - Konfiguration:
     ```xml
     <configuration>
         <host>ldap_server</host>
         <port>3389</port>
         <baseContext>dc=example,dc=com</baseContext>
         <bindDn>cn=Directory Manager</bindDn>
         <bindPassword>1234</bindPassword>
         <passwordAttribute>userPassword</passwordAttribute>
     </configuration>
     ```



### 2.3 Benutzer von MidPoint nach LDAP synchronisieren
1. Erstellen Sie einen neuen Benutzer in MidPoint
2. Weisen Sie dem Benutzer die LDAP-Resource zu
3. Der Benutzer wird automatisch nach LDAP synchronisiert
4. Überprüfen Sie die Synchronisation mit:
   ```bash
   podman exec ldap_server ldapsearch -x -H ldap://localhost:3389 \
     -D "cn=Directory Manager" -w 1234 \
     -b "ou=users,dc=example,dc=com" "(uid=neuerbenutzer)"
   ```

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZPqFWT4nUkEPTiNua2h1GQeRh9a4vkz2AUyU4uLibj1GpYvE93U8soTyjjZsvQZHV.png)
*Dem Benutzer "029" wird die Resource "LDAP" zugewiesen*

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tRvE6g4YLXWWh53ZhsM5FAnQ8aqnLWDTPYwGpYXVKNAwFFbnNRzd2zByGNuK5bXvxmT.png)
*Da die Resource "LDAP" sauber funktioniert (Konfiguration siehe [hier](https://peakd.com/hive-121566/@achimmertens/wie-man-mit-dem-iga-server-midpoint-hr-user-nach-ldap-exportiert)), wird der User sofort nach dem Speichern zum LDAP-Server synchronisiert*


## 3. LDAP-Server Setup

### 3.1 Container starten
```bash
# Start the LDAP server with network configuration

podman run --network midpoint_net \
 -p 3389:3389 -p 3636:3636 \
 --name ldap_server \
 -e DS_DM_PASSWORD=1234 \
 -e DS_SUFFIX_NAME="dc=example,dc=com" \
 -v ldap_data:/data \
 389ds/dirsrv

# podman start -a ldap_server
```

### 3.2 LDAP-Benutzer anzeigen
Ein Beispielbenutzer ist bereits angelegt:
- Username: john.doe
- Password: password
- DN: uid=john.doe,ou=users,dc=example,dc=com

Um weitere Benutzer anzuzeigen:
```bash
podman exec ldap_server ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "ou=users,dc=example,dc=com" "(objectClass=inetOrgPerson)"
```

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo43uki9Qb3ebuDjbh2j2xkwjenBKtp8m8ta96AK78x6hpysp6p4mX35YLb48MX9Xde.png)


## 3. Keycloak Setup

### 3.1 Container starten
```bash
# Start Keycloak server with network configuration
podman run -p 8081:8080 \
  --network midpoint_net \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_PROXY=edge \
  -e KC_HOSTNAME_STRICT=false \
  -e KC_HOSTNAME_STRICT_HTTPS=false \
  -e KC_HOSTNAME=localhost:8081 \
  --name keycloak_server \
  quay.io/keycloak/keycloak:21.0.2 \
  start-dev
```

### 3.2 LDAP-Integration in Keycloak einrichten
1. Öffnen Sie http://localhost:8081
2. Login mit admin/admin
3. Gehen Sie zu "User Federation"
4. ![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tvwZVmmK4w4vHRiLwjQkSKyyp9TeS32C26eWCqLsisTrcy2AZRytuJCXy2j75qhXiFH.png)
5. Fügen Sie einen neuen LDAP-Provider hinzu:
   - Connection URL: ldap://[LDAP-IP]:3389 (IP mit `podman inspect ldap_server` ermitteln)
   - Enable StartTLS: OFF
   - Bind Type: simple
   - Bind DN: cn=Directory Manager
   - Bind Credentials: 1234
   - Users DN: ou=users,dc=example,dc=com
   - Username LDAP attribute: uid
   - RDN LDAP attribute: uid
   - UUID LDAP attribute: entryUUID
   - User Object Classes: inetOrgPerson, organizationalPerson, person
6. Klicken Sie auf "Test connection"
7. Speichern Sie und klicken Sie auf "Synchronize all users"

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EoCnzmcLgg5fFaU3PgzHfjrYQAbdgDGYVrgsZs3D8mRGjhL8tjJQCiRbddLCet2ED4V.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23sxjqWgwoEvxzZ3JbBQKhAyUrYEYZbVWxP3C6AJwToKhs1QPg1Ue7S4cv2Viod4Sh4md.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/48GFLC3H7PU5dyyUz3rjornt7GqPrJeSCoLKq4MZ9A88n6ZgijuQ9JhYxbNeTrPNSM.png)

### 3.3 Client für Nginx erstellen
1. Gehen Sie zu "Clients" → "Create client"
2. Konfigurieren Sie:
   - Client ID: nginx-client
   - Client authentication: ON
   - Valid redirect URIs: http://localhost:8080/oauth2/callback
   - Web origins: http://localhost:8080
3. Speichern Sie die Änderungen
4. Notieren Sie sich das Client Secret aus dem "Credentials" Tab
   ![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23xL9TJubBcqUn3yBAotn7vNA59ntricJ9UoG2fcyV1vZAQZYkvDvhVpdiGCx4ThCrj65.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CfKjHAuGbhZL3pLwjGFSxCW3mMgi2QaPMstXFJUw9Y2i2tLTuXTTiwhg1HHdsF7pL.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8DBnQEzrxfcQ3dcEddaQERrw8jKu4SrzSrkjp1AcwTbCLvUAJ6GGv7671s6Q8G679v.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8DBnQFMQYTUGzWNC3auHikYCQRJXCKz2pus2y8QCvkcadbeBg6JzNf5dDVfpFNUmNx.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CSPYK3e3KY4cN54pMfvExFmYZa5NHGeE4bPjvHCwMc3X31qrRpwGriYpejrjhJhbu.png)

## 4. Nginx Setup

### 4.1 Nginx Konfiguration
#### Erstellen Sie die Datei `default.conf`:

```nginx
server {
    listen 80;
    server_name localhost;

    # Debug-Logging aktivieren
    error_log /var/log/nginx/error.log debug;
    access_log /var/log/nginx/access.log main;
    
    # OAuth2 Proxy Config
    set $oauth2_callback_url "http://localhost:8080/oauth2/callback";
    set $oauth2_client_secret "your-client-secret";    # Root directory
    root /usr/share/nginx/html;
    index index.html;

    # Unprotected welcome page
    location = /welcome.html {
        root /usr/share/nginx/html;
        auth_request off;  # Explicitly disable auth for this location
    }

    # Protected content
    location / {
        # Error handling
        error_page 401 = @login;
        error_page 500 502 503 504 /50x.html;

        # Auth validation
        auth_request /oauth2/auth;
        auth_request_set $auth_status $upstream_status;

        # Default to welcome page after authentication
        try_files /welcome.html $uri $uri/ /index.html;

        # Debug headers
        add_header X-Debug-Auth-Status $auth_status;
        add_header X-Debug-Uri $uri;
    }

    # Error page
    location = /50x.html {
        root /usr/share/nginx/html;
        internal;
    }

    # Login redirect
    location @login {
        return 302 "http://localhost:8081/realms/master/protocol/openid-connect/auth?response_type=code&client_id=nginx-client&redirect_uri=$oauth2_callback_url&scope=openid%20profile%20email";
    }

    # OAuth2 authorization validation
    location = /oauth2/auth {
        internal;
        proxy_pass http://localhost:8081/realms/master/protocol/openid-connect/userinfo;
        proxy_set_header Host localhost:8081;
        
        # Wenn kein Token vorhanden ist, direkt 401 zurückgeben
        if ($cookie_oauth2_token = "") {
            return 401;
        }
        
        # Pass the OAuth token from cookie
        proxy_set_header Authorization "Bearer $cookie_oauth2_token";
        
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";

        # Debug headers
        add_header X-Debug-Token $cookie_oauth2_token;
        add_header X-Debug-Auth $http_authorization;
    }    # OAuth2 callback
    location = /oauth2/callback {
        proxy_pass http://localhost:8081/realms/master/protocol/openid-connect/token;
        proxy_set_header Host localhost:8081;
        proxy_set_header Content-Type "application/x-www-form-urlencoded";
        
        # Exchange the authorization code for tokens
        proxy_method POST;
        proxy_set_body "grant_type=authorization_code&client_id=nginx-client&client_secret=$oauth2_client_secret&code=$arg_code&redirect_uri=$oauth2_callback_url";
        
        # Save the access token in a cookie
        add_header Set-Cookie "oauth2_token=$upstream_http_access_token;Path=/;HttpOnly;SameSite=Lax;Max-Age=3600";
          # Debug headers
        add_header X-Debug-Token-Response $upstream_http_access_token;
        
        # After successful login, redirect to welcome page
        return 302 "http://localhost:8080/welcome.html";
    }
}

```

#### nginx.conf

Hier wird das Client Secret vom Keycloak eingetragen:
```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Basic settings
    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;
    types_hash_max_size 2048;

    # Logging
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    error_log   /var/log/nginx/error.log  debug;

    # OAuth2 configuration variables
    map $http_host $oauth2_client_id {
        default "nginx-client";
    }
    map $http_host $oauth2_client_secret {
        default "6ISR2zLR2P7SsTAu23rOfta0tPOBLsfF";
    }

    # Include site configurations
    include /etc/nginx/sites-enabled/*.conf;
}

```

### 4.2 Container starten
```bash
# Start Nginx server with network configuration
podman stop nginx_webserver || true
podman rm nginx_webserver || true

# Create required directories
mkdir -p /d/IAM/nginx/html
mkdir -p /d/IAM/nginx/logs

# Copy HTML files
cp -f /d/IAM/nginx/index.html /d/IAM/nginx/html/
cp -f /d/IAM/nginx/50x.html /d/IAM/nginx/html/

# Touch log files to ensure they exist
touch /d/IAM/nginx/logs/error.log
touch /d/IAM/nginx/logs/access.log

# Start the container
podman run --name nginx_webserver \
  --network midpoint_net \
  --dns 127.0.0.11 \
  --mount type=bind,source=/d/IAM/nginx/nginx.conf,target=/etc/nginx/nginx.conf,readonly \
  --mount type=bind,source=/d/IAM/nginx/sites-enabled,target=/etc/nginx/sites-enabled,readonly \
  --mount type=bind,source=/d/IAM/nginx/html,target=/usr/share/nginx/html \
  --mount type=bind,source=/d/IAM/nginx/logs,target=/var/log/nginx \
  -p 8080:80 \
  nginx:latest

# Install diagnostic tools
# podman exec -it nginx_webserver bin/bash
# apt-get update && apt-get install -y curl
```

## 5. Testing

1. Öffnen Sie http://localhost:8080 in einem privaten Browserfenster
2. Sie werden zur Keycloak-Anmeldeseite weitergeleitet
3. Melden Sie sich mit LDAP-Credentials an (z.B. john.doe/password)
4. Nach erfolgreicher Anmeldung werden Sie zur geschützten Seite weitergeleitet


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/244ojeAQQaVUNQyUyUdvwZkEuaYnLAWUtdjumLBPLc78ByL5nAd3A21dMeGAHL759qWX6.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tw7oNjU4grG6BLYihs3fU8rj6Ggyrhqr3xcsZFwtq47EmjrPbBh6YJEpyv6MW5FCjcy.png)



## 6. Fehlersuche und Debugging

### LDAP-Verbindung testen
```bash
podman exec ldap_server ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "ou=users,dc=example,dc=com"
```

### LDAP-IP ermitteln
```bash
podman inspect ldap_server --format '{{.NetworkSettings.Networks.midpoint_net.IPAddress}}'
```

### Nginx-Logs anzeigen
```bash
podman logs nginx_webserver
```

### Keycloak-Logs anzeigen
```bash
podman logs keycloak_server
```

### Container-Status überprüfen
```bash
# Status aller Container anzeigen
podman ps -a

# Detaillierte Container-Informationen
podman inspect container_name

# Container-Logs in Echtzeit verfolgen
podman logs -f container_name
```

### Netzwerk-Debugging
```bash
# Container-IP-Adressen anzeigen
podman inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(podman ps -q)

# Netzwerke auflisten
podman network ls

# Netzwerk-Details anzeigen
podman network inspect midpoint_net
```

### Häufige Probleme und Lösungen

1. Nginx kann Keycloak nicht erreichen:
   - Überprüfen Sie die Container-IPs
   - Testen Sie die Verbindung: `podman exec nginx_server curl -v http://keycloak_server:8080`
   - Prüfen Sie die Nginx-Konfiguration auf korrekte Hostnamen/IPs

2. LDAP-Synchronisation schlägt fehl:
   - Testen Sie die LDAP-Verbindung direkt
   - Überprüfen Sie die LDAP-Zugangsdaten
   - Prüfen Sie die Berechtigungen im LDAP

3. Keycloak-Authentifizierung funktioniert nicht:
   - Überprüfen Sie das Client Secret
   - Prüfen Sie die Redirect URIs
   - Kontrollieren Sie die Cookie-Einstellungen

4. Redirect-Schleifen in Nginx:
   - Stellen Sie sicher, dass /welcome.html nicht geschützt ist
   - Überprüfen Sie die Auth-Request-Konfiguration
   - Prüfen Sie die Cookie-Handhabung

# Fazit
Jetzt können wir nach belieben User in Midpoint importieren und dort nach allen Regeln der Kunst verwalten (Rechte und Rollen verteilen, Passwortmanagement, Auditprozesse,...). Diese User können wir an (beliebige) LDAP-Server weiterreichen. Der Keycloak, der zustängig ist für Access Management (Single Sign on, Multi Faktor Authentifizierung,...) sorgt dafür, dass der User sich anmelden kann. Und Nginx wird dann an Keycloak angebunden, so dass gewährleistet wird, dass nur die User auf die Webseite zugreifen können, die dass auch dürfen. Über ein Rollenmanagement, dass in der Webseite hinterlegt werden und mit Midpoint synchronisiert werden kann, wird gewährleistet, dass der User sich nicht nur authentifizieren, sondern auch für die jeweiligen Bedürfnisse (Rechte und Einschränkungen) autorisieren kann.

Der komplette Code befindet sich übrigens hier: https://github.com/achimmertens/IAM

Details werden bstimmt noch folgen, so stay tuned,

Achim Mertens
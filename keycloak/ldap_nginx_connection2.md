# Vollständiger IAM-Stack: MidPoint, LDAP, Keycloak und Nginx Integration

Diese Dokumentation beschreibt die vollständige Integration eines Identity and Access Management (IAM) Stacks bestehend aus MidPoint, LDAP, Keycloak und Nginx. Der Stack ermöglicht:

1. Benutzer-Management in MidPoint
2. Synchronisation der Benutzer mit LDAP
3. SSO-Authentifizierung über Keycloak
4. Geschützte Webseiten mit Nginx

## 1. Systemarchitektur & Netzwerk-Setup

### 1.1 Komponenten
Das System besteht aus vier Hauptkomponenten, die alle in separaten Podman-Containern laufen:
1. MidPoint: Identity Management System
2. LDAP-Server (389ds): Verwaltet Benutzerkonten
3. Keycloak-Server: Handhabt die Authentifizierung
4. Nginx-Server: Stellt die geschützte Webseite bereit

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
2. Loggen Sie sich als Administrator ein (admin/5ecr3t)
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

### 3.2 LDAP-Benutzer anlegen
Ein Beispielbenutzer ist bereits angelegt:
- Username: john.doe
- Password: password
- DN: uid=john.doe,ou=users,dc=example,dc=com

Um weitere Benutzer anzuzeigen:
```bash
podman exec ldap_server ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "ou=users,dc=example,dc=com" "(objectClass=inetOrgPerson)"
```

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
4. Fügen Sie einen neuen LDAP-Provider hinzu:
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
5. Klicken Sie auf "Test connection"
6. Speichern Sie und klicken Sie auf "Synchronize all users"

### 3.3 Client für Nginx erstellen
1. Gehen Sie zu "Clients" → "Create client"
2. Konfigurieren Sie:
   - Client ID: achimsclient
   - Client authentication: ON
   - Valid redirect URIs: http://localhost:8080/oauth2/callback
   - Web origins: http://localhost:8080
3. Speichern Sie die Änderungen
4. Notieren Sie sich das Client Secret aus dem "Credentials" Tab

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

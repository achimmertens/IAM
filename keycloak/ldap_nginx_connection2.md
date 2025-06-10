# LDAP, Keycloak und Nginx Integration Guide

Diese Dokumentation beschreibt, wie man eine durch Keycloak geschützte Webseite aufsetzt, die LDAP für die Benutzerverwaltung nutzt.

## Systemarchitektur

Das System besteht aus drei Hauptkomponenten, die alle in separaten Podman-Containern laufen:
1. LDAP-Server (389ds): Verwaltet Benutzerkonten
2. Keycloak-Server: Handhabt die Authentifizierung
3. Nginx-Server: Stellt die geschützte Webseite bereit

## 1. LDAP-Server Setup

### 1.1 Container starten
```bash
podman run -p 3389:3389 \
  --network iam_network \
  --name ldap_server \
  389ds/dirsrv:latest
```

### 1.2 LDAP-Benutzer anlegen
Ein Beispielbenutzer ist bereits angelegt:
- Username: john.doe
- Password: password
- DN: uid=john.doe,ou=users,dc=example,dc=com

Um weitere Benutzer anzuzeigen:
```bash
podman exec ldap_server ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "ou=users,dc=example,dc=com" "(objectClass=inetOrgPerson)"
```

## 2. Keycloak Setup

### 2.1 Container starten
```bash
podman run -p 8081:8080 \
  --network iam_network \
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

### 2.2 LDAP-Integration in Keycloak einrichten
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

### 2.3 Client für Nginx erstellen
1. Gehen Sie zu "Clients" → "Create client"
2. Konfigurieren Sie:
   - Client ID: achimsclient
   - Client authentication: ON
   - Valid redirect URIs: http://localhost:8080/oauth2/callback
   - Web origins: http://localhost:8080
3. Speichern Sie die Änderungen
4. Notieren Sie sich das Client Secret aus dem "Credentials" Tab

## 3. Nginx Setup

### 3.1 Nginx Konfiguration
Erstellen Sie die Datei `default.conf`:

```nginx
server {
    listen 80;
    server_name localhost;

    # OAuth2 configuration
    set $oauth2_client_id "achimsclient";
    set $oauth2_client_secret "[IHR_CLIENT_SECRET]";
    set $oauth2_redirect_uri "http://localhost:8080/oauth2/callback";
    set $oauth2_keycloak_url "http://localhost:8081";

    # Protected content
    location / {
        auth_request /auth;
        auth_request_set $auth_status $upstream_status;
        auth_request_set $auth_cookie $upstream_http_set_cookie;
        auth_request_set $saved_token $upstream_http_authorization;
        
        proxy_set_header Authorization $saved_token;
        error_page 401 = @error401;

        root /usr/share/nginx/html;
        index index.html;
    }

    # Handle 401 errors by redirecting to login
    location @error401 {
        return 302 "$oauth2_keycloak_url/realms/master/protocol/openid-connect/auth?response_type=code&client_id=$oauth2_client_id&redirect_uri=$oauth2_redirect_uri&scope=openid%20profile%20email";
    }

    # OAuth2 callback handler
    location = /oauth2/callback {
        proxy_pass http://keycloak_server:8080/realms/master/protocol/openid-connect/token;
        proxy_set_header Host $http_host;
        proxy_set_header Content-Type "application/x-www-form-urlencoded";
        proxy_method POST;
        proxy_set_body "grant_type=authorization_code&client_id=$oauth2_client_id&client_secret=$oauth2_client_secret&code=$arg_code&redirect_uri=$oauth2_redirect_uri";
        
        proxy_intercept_errors off;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;

        add_header Set-Cookie "access_token=$upstream_http_access_token;Path=/;HttpOnly;SameSite=Lax;Max-Age=3600";
        
        return 302 http://localhost:8080/;
    }

    # Internal authentication request
    location = /auth {
        internal;
        proxy_pass http://keycloak_server:8080/realms/master/protocol/openid-connect/userinfo;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI $request_uri;
        proxy_set_header Authorization "Bearer $cookie_access_token";
    }
}
```

### 3.2 Container starten
```bash
podman run --name nginx_webserver \
  --network iam_network \
  --mount type=bind,source=/path/to/nginx,target=/usr/share/nginx/html,readonly \
  --mount type=bind,source=/path/to/nginx/default.conf,target=/etc/nginx/conf.d/default.conf,readonly \
  -p 8080:80 \
  nginx:latest
```

## 4. Testing

1. Öffnen Sie http://localhost:8080 in einem privaten Browserfenster
2. Sie werden zur Keycloak-Anmeldeseite weitergeleitet
3. Melden Sie sich mit LDAP-Credentials an (z.B. john.doe/password)
4. Nach erfolgreicher Anmeldung werden Sie zur geschützten Seite weitergeleitet

## Fehlersuche

### LDAP-Verbindung testen
```bash
podman exec ldap_server ldapsearch -x -H ldap://localhost:3389 -D "cn=Directory Manager" -w 1234 -b "ou=users,dc=example,dc=com"
```

### LDAP-IP ermitteln
```bash
podman inspect ldap_server --format '{{.NetworkSettings.Networks.iam_network.IPAddress}}'
```
oder

podman inspect ldap_server --format '{{.NetworkSettings.Networks.midpoint_net.IPAddress}}'

### Nginx-Logs anzeigen
```bash
podman logs nginx_webserver
```

### Keycloak-Logs anzeigen
```bash
podman logs keycloak_server
```

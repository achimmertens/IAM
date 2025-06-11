# OAuth2 Authentifizierungsablauf

## 1. Erste Authentifizierung

### 1.1 Initiale Anfrage
Wenn ein Benutzer zum ersten Mal http://localhost:8080 aufruft:

1. Browser -> Nginx:
   ```http
   GET / HTTP/1.1
   Host: localhost:8080
   ```

2. Nginx prüft auf oauth2_token Cookie (nicht vorhanden)
3. Nginx antwortet mit 401 & Weiterleitung zu Keycloak

### 1.2 Keycloak Login
1. Browser wird zu Keycloak Login weitergeleitet:
   ```http
   HTTP/1.1 302 Found
   Location: http://localhost:8081/realms/master/protocol/openid-connect/auth?
     response_type=code&
     client_id=nginx-client&
     redirect_uri=http://localhost:8080/oauth2/callback&
     scope=openid%20profile%20email
   ```

2. Benutzer gibt Credentials ein
3. Keycloak prüft Credentials gegen LDAP
4. Bei erfolgreicher Anmeldung generiert Keycloak einen Authorization Code

### 1.3 Token-Austausch
1. Keycloak leitet zurück an Nginx mit Code:
   ```http
   HTTP/1.1 302 Found
   Location: http://localhost:8080/oauth2/callback?code=abc123...
   ```
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHbTvTQzpa2sxY8Uk1UuMKL83qUsLFU6tjxpFtByqyrb2WtX7NwtqjWjv7n5uP1SAi1.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tSz3RGcCKy3EnedgGYHjNUsJuG63nTE6316fTqGZhstA8u6aedhXpyWowE2ZTD79VRq.png)

2. Nginx tauscht Code gegen Token:
   ```http
   POST /realms/master/protocol/openid-connect/token HTTP/1.1
   Host: localhost:8081
   Content-Type: application/x-www-form-urlencoded

   grant_type=authorization_code&
   client_id=nginx-client&
   client_secret=your-secret&
   code=abc123...&
   redirect_uri=http://localhost:8080/oauth2/callback
   ```

3. Keycloak antwortet mit Tokens:
   ```json
   {
     "access_token": "eyJ...",
     "token_type": "Bearer",
     "expires_in": 3600,
     "refresh_token": "eyJ...",
     "id_token": "eyJ..."
   }
   ```

## 2. Token-Details

### 2.1 Access Token (JWT)
Base64-decodierter Inhalt:
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "..."
  },
  "payload": {
    "sub": "f:123...",         // Unique Subject ID
    "email": "user@example.com",
    "name": "John Doe",
    "given_name": "John",
    "family_name": "Doe",
    "preferred_username": "john.doe",
    "email_verified": true,
    "iat": 1623318000,        // Issued At
    "exp": 1623321600,        // Expires At
    "iss": "http://localhost:8081/realms/master",
    "aud": "nginx-client"
  },
  "signature": "..."
}
```

### 2.2 Cookie-Speicherung
Nginx speichert das Token als sicheres Cookie:
```http
Set-Cookie: oauth2_token=eyJ...;
           Path=/;
           HttpOnly;        // Nicht über JavaScript zugreifbar
           SameSite=Lax;   // CSRF-Schutz
           Max-Age=3600    // 1 Stunde Gültigkeit
```
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23uRJ9mS2bMVrKGMWhbDABt8ZwShz8E8VSXHuckd2qHtjiyrLBzhNTmoCPB34Kc4b3mqJ.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8AegvhRCL8QubAcD1uaVVstyhwK8MAe7pSpBA7BGdfLWUGrUhbRakaP7EiqUpskNUf.png)
## 3. Nachfolgende Anfragen

### 3.1 Authentifizierte Anfrage
1. Browser sendet Request mit Cookie:
   ```http
   GET / HTTP/1.1
   Host: localhost:8080
   Cookie: oauth2_token=eyJ...
   ```

2. Nginx validiert Token bei Keycloak:
   ```http
   GET /realms/master/protocol/openid-connect/userinfo HTTP/1.1
   Host: localhost:8081
   Authorization: Bearer eyJ...
   ```

3. Bei gültigem Token:
   - Keycloak bestätigt Token-Gültigkeit
   - Nginx liefert geschützten Inhalt

### 3.2 Token-Erneuerung
- Access Token läuft nach 1 Stunde ab
- Refresh Token kann für neue Access Tokens verwendet werden
- Bei ungültigem Token: Neue Anmeldung erforderlich

## 4. Sicherheitsaspekte

### 4.1 Token-Sicherheit
- Tokens sind signiert (RS256)
- Nur über HTTPS übertragen (in Produktion)
- HttpOnly verhindert XSS-Zugriff
- SameSite=Lax verhindert CSRF

### 4.2 Server-seitige Validierung
- Jede Anfrage wird bei Keycloak validiert
- Token-Blacklisting bei Logout möglich
- Keine Token-Speicherung in Nginx

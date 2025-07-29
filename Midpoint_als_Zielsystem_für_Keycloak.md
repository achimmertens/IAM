
https://docs.evolveum.com/midpoint/reference/before-4.8/security/authentication/flexible-authentication/configuration/

https://docs.evolveum.com/talks/files/2024-11-inalogy-keycloak-as-an-access-layer.pdf

https://www.youtube.com/watch?v=Www6aYk7zmk


Grundprinzip

Das flexible Authentifizierungssystem von MidPoint ermöglicht die Kombination verschiedener Authentifizierungsmethoden (Module) zu frei definierbaren Authentifizierungssequenzen, die über sogenannte Kanäle bestimmten Anwendungsbereichen (z.B. GUI, REST-API) zugeordnet werden können.

Die XML Datei ist daher in folgende Blöcke aufgeteilt (unteres Beispiel):
- Module (Hier: loginForm, oidc)
- Kanäle (Hier: http://midpoint.evolveum.com/xml/ns/public/common/channels-3#user)
- Sequenz (Reienfolge, hier: oicd, loginForm)

In Midpoint eintragen:
```
<securityPolicy xmlns:t="http://prism.evolveum.com/xml/ns/public/types-3">
  <authentication>
    <modules>
      <loginForm>
        <identifier>loginForm</identifier>
      </loginForm>
      <oidc>
        <identifier>gui-oidc</identifier>
        <client>
          <registrationId>oidc-registration</registrationId>
          <clientId>midpoint</clientId>
          <clientSecret>
            <t:clearValue>cXSJeVGV0PcFIJmKcrRHrVvQR8oXFHkp</t:clearValue>
          </clientSecret>
          <clientAuthenticationMethod>clientSecretBasic</clientAuthenticationMethod>
          <nameOfUsernameAttribute>preferred_username</nameOfUsernameAttribute>
          <openIdProvider>
            <issuerUri>http://localhost:8081/admin/master</issuerUri>
          </openIdProvider>
        </client>
      </oidc>
    </modules>
    <sequence>
      <module>gui-oidc</module>
    </sequence>
  </authentication>
</securityPolicy>

```

oder besser:

```
<securityPolicy>
  <authentication>
    <modules>
      <loginForm>
        <identifier>loginForm</identifier>
      </loginForm>
      <oidc>
        <identifier>gui-oidc</identifier>
        <client>
          <registrationId>oidc-registration</registrationId>
          <clientId>midpoint</clientId>
          <clientSecret>
            <t:clearValue>SECRET</t:clearValue>
          </clientSecret>
          <clientAuthenticationMethod>clientSecretBasic</clientAuthenticationMethod>
          <nameOfUsernameAttribute>preferred_username</nameOfUsernameAttribute>
          <openIdProvider>
            <issuerUri>http://keycloak:8080/realms/master</issuerUri>
          </openIdProvider>
        </client>
      </oidc>
    </modules>
    <sequence>
      <identifier>gui-oidc</identifier>
      <channel>
        <channelId>http://midpoint.evolveum.com/xml/ns/public/common/channels-3#user</channelId>
        <default>true</default>
        <urlSuffix>gui-oidc</urlSuffix>
      </channel>
      <module>
        <identifier>gui-oidc</identifier>
      </module>
    </sequence>
    <sequence>
      <identifier>gui-login-form</identifier>
      <channel>
        <channelId>http://midpoint.evolveum.com/xml/ns/public/common/channels-3#user</channelId>
        <urlSuffix>gui-login-form</urlSuffix>
      </channel>
      <module>
        <identifier>loginForm</identifier>
      </module>
    </sequence>
  </authentication>
</securityPolicy>

```


# Keycloak Connector installieren


1. Keycloak-Connector bereitstellen

    Lade den Keycloak-Connector herunter (z.B. von [GitHub](https://github.com/openstandia/connector-keycloak
    )) oder Maven Central). 

    Erstelle die .jar Datei mit:
    mvn install -Dgpg.skip=true
    
    ![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tbMAxbrFAjNbWKs8B4m1TzefrD9EnTZTNxWUhV1wu3UrcxyHNTmoDnkZjVPPuhz9PoH.png)

    Lege die JAR-Datei im Connector-Verzeichnis deiner MidPoint-Installation ab (z.B. /opt/midpoint/var/icf-connectors, was bei mir als Midpoint-Home mit .../IAM/midpoint gemappt ist).
    
    ![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t78ng8DYDBm2vkP7sZaMGDSSH6EG2iVZ7bcSYE6XSPy5cadvhTjuaXhAij7cz7BReme.png)

    Ich musste die Datei noch nach /opt/midpoint/var/connid-connectors verschieben:
    ![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tRvZr5QMgLMA8WMfifBotJstGsg5RmayW53h5K2X2yVXbZ33wjTyGFAEmhBLX7rpP1d.png)

2. Resource in MidPoint anlegen

    Gehe in die MidPoint-GUI → Ressourcen → Neue Resource anlegen/from Scratch. (Bei mir dauerte es ein paar Minuten, bis der Konnector erschien.)

    Wähle als Connector den Keycloak-Connector aus (meist jp.openstandia.connector.keycloak.KeycloakConnector).
    
    ![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tHZgM8nHmy2eKiAEJPRRWjip3iTadLTKaniM2Ckgbp62i2uQ6HLA2zqFv4orkCCuyMA.png)

    Gib die Verbindungsdaten zu deinem Keycloak-Server an (URL, Realm, Client, Secret, ggf. Admin-User/Passwort).


    http://keycloak_server:8080/admin/serverinfo

    Erklärung: Keyclaok_server ist die IP-Adresse im Containernetz, also z.B. 10.89.0.6. Sie wird automatisch aufgelöst.
    8080 ist der Port, der intern im Container verwendet wird.
    Mit dieser Kombination ist es schon mal möglich auf den Keycloak-Server zuzugreifen. Ich erhalte allerding die Meldung:
    jakarta.ws.rs.NotAuthorizedException(HTTP 401 Unauthorized)
    obwohl ich sehr sicher die Passwörter und Secret korrekt eingegeben habe.


3. Schema laden und Testverbindung

    Lade das Schema der Resource, um die verfügbaren Objekttypen (User, Gruppen) zu sehen.

    Teste die Verbindung.

4. Synchronisation und Provisionierung

    Du kannst jetzt Benutzer und Gruppen aus Keycloak als Accounts in MidPoint sehen, synchronisieren und ggf. Provisionierungsregeln definieren.

    Auch die Zuweisung von Keycloak-Rollen ist über den Connector möglich

    .

    Du kannst gezielt die Keycloak-Admin-User synchronisieren oder in MidPoint verwalten, indem du entsprechende Filter und Mappings definierst.

# Keycloak Admin API
Export der Konfiguration (JSON)
Falls du Zugriff auf die Keycloak-Admin-API hast, kannst du den Client als JSON exportieren und hier posten:

bash
Kopieren
Bearbeiten
# Beispiel:
kcadm.sh get clients/<id> -r master
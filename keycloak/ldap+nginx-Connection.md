https://www.perplexity.ai/search/ich-habe-lokal-auf-meinem-pc-m-zCCOXrXZRlOYpeuEaVgdDQ

# Keycloak-Client für Nginx konfigurieren

 Erstellen Sie in Keycloak einen neuen OpenID Connect-Client:

 Client ID: z.B. nginx-client

 Client Protocol: openid-connect

 Access Type: confidential (für Client Secret)

 Redirect URI: https://<Ihre-Nginx-Domain>/oidc_callback 

Notieren Sie das Client Secret aus dem Keycloak-Admininterface
.

Konkret:
Aufrufen von Keycloak: http://localhost:8081/
Klicken auf "Administration Console"
Login mit admin admin
Clients/create client
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23xL9TJubBcqUn3yBAotn7vNA59ntricJ9UoG2fcyV1vZAQZYkvDvhVpdiGCx4ThCrj65.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CfKjHAuGbhZL3pLwjGFSxCW3mMgi2QaPMstXFJUw9Y2i2tLTuXTTiwhg1HHdsF7pL.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8DBnQEzrxfcQ3dcEddaQERrw8jKu4SrzSrkjp1AcwTbCLvUAJ6GGv7671s6Q8G679v.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8DBnQFMQYTUGzWNC3auHikYCQRJXCKz2pus2y8QCvkcadbeBg6JzNf5dDVfpFNUmNx.png)
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23t8CSPYK3e3KY4cN54pMfvExFmYZa5NHGeE4bPjvHCwMc3X31qrRpwGriYpejrjhJhbu.png)
qWxLrlOfBvkzwfXYzza3ZMtWjgDzNMfp

----------------------------------------

LDAP-Integration in Keycloak einrichten

    Gehen Sie in Keycloak zu User Federation → LDAP:

        Verbindungsparameter:

            LDAP-URL: ldap://<LDAP-Server-IP>

            Bind Type: simple

            Bind DN: Admin-DN des LDAP-Servers

            Bind Credentials: Passwort des LDAP-Admin

        Synchronisation aktivieren und Periodic Sync konfigurieren

Mapper für Attribute wie username, email und roles hinzufügen

Konkret:


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tvwZVmmK4w4vHRiLwjQkSKyyp9TeS32C26eWCqLsisTrcy2AZRytuJCXy2j75qhXiFH.png)

Eigentlich sollte als ldap-Adresse "ldap://ldap_server:3389" angegeben werden. Klappt bei mir aber nicht. Um die wahre LDAP-Adresse zu finden geben wir ein:

podman inspect ldap_server --format '{{.NetworkSettings.Networks.iam_network.IPAddress}}'

-> 10.89.1.7

Gehen Sie zu http://localhost:8081
Melden Sie sich als admin/admin an
Gehen Sie zu User Federation
Fügen Sie einen neuen LDAP Provider hinzu mit den folgenden Einstellungen:
Connection URL: ldap://10.89.1.7:3389
Enable StartTLS: OFF
Bind Type: simple
Bind DN: cn=Directory Manager
Bind Credentials: 1234
Users DN: ou=users,dc=example,dc=com
Username LDAP attribute: uid
RDN LDAP attribute: uid
UUID LDAP attribute: entryUUID
User Object Classes: inetOrgPerson, organizationalPerson, person


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/EoCnzmcLgg5fFaU3PgzHfjrYQAbdgDGYVrgsZs3D8mRGjhL8tjJQCiRbddLCet2ED4V.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23sxjqWgwoEvxzZ3JbBQKhAyUrYEYZbVWxP3C6AJwToKhs1QPg1Ue7S4cv2Viod4Sh4md.png)


![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/48GFLC3H7PU5dyyUz3rjornt7GqPrJeSCoLKq4MZ9A88n6ZgijuQ9JhYxbNeTrPNSM.png)

----

# nginx konfiguration

podman exec nginx_webserver nginx -T

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/Eo44Mxh1jEraZc4TuRYRzHCSoqBfaAEnVUzWmJw4DNdHHPFWN8FanWBPTJZmDgGC5pd.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGVdRvEcMNpy61VFfQFGkFGjNayZL568Na9easbczbHZMuEpMCf8F3VDujmhM61eEHA.png)

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23swibA2TesgnqoyuiLNMSwVQnqGqB4jXGKmh1Cu4y87fL12nqFdZZwEWEN5v7gooe7Yp.png)

Ja, die Konfiguration wurde korrekt geladen! Wir sehen:

Die auth_request Module sind aktiviert

Die Keycloak-Integration ist konfiguriert

Die OAuth2-Endpunkte sind eingerichtet

podman exec nginx_webserver nginx -s reload

Let's update the index.html to include a proper protected page:

index.html+19-4

Nach dem Redirect auf den KEycloakserver muss noch  mehr gemacht werden:
curl -X POST http://localhost:8081/realms/master/protocol/openid-connect/token -d "client_id=admin-cli" -d "username=admin" -d "password=admin" -d "grant_type=password"



$ podman network inspect midpoint_net
[
     {
          "name": "midpoint_net",
          "id": "74a61e22662e7ae93c7c04d9fcffc7e651b815a69a7d2f9c788b554b9ebfde7c",
          "driver": "bridge",
          "network_interface": "podman1",
          "created": "2025-04-03T10:35:36.747696505+02:00",
          "subnets": [
               {
                    "subnet": "10.89.0.0/24",
                    "gateway": "10.89.0.1"
               }
          ],
          "ipv6_enabled": false,
          "internal": false,
          "dns_enabled": true,
          "labels": {
               "com.docker.compose.network": "net",
               "com.docker.compose.project": "midpoint",
               "com.docker.compose.version": "2.29.7"
          },
          "options": {
               "isolate": "true"
          },
          "ipam_options": {
               "driver": "host-local"
          },
          "containers": {
               "2dec3cf96705579109103f6517152d9c0b4f406f36db5e32a48dbe566bc70aa1": {
                    "name": "keycloak_server",
                    "interfaces": {
                         "eth0": {
                              "subnets": [
                                   {
                                        "ipnet": "10.89.0.9/24",
                                        "gateway": "10.89.0.1"
                                   }
                              ],
                              "mac_address": "da:19:82:42:ce:19"
                         }
                    }
               },
               "a8f271bd0023f3dfc71c98a77c12ec2ff4f6f9ba494dc95c09dab56ccafec0ee": {
                    "name": "midpoint-midpoint_server-1",
                    "interfaces": {
                         "eth0": {
                              "subnets": [
                                   {
                                        "ipnet": "10.89.0.7/24",
                                        "gateway": "10.89.0.1"
                                   }
                              ],
                              "mac_address": "8e:7c:af:0f:7e:2f"
                         }
                    }
               },
               "b1cb687525ea42b730b967645a5c42ae192e63ff4c99d2b281abea0c97f40feb": {
                    "name": "ldap_server",
                    "interfaces": {
                         "eth0": {
                              "subnets": [
                                   {
                                        "ipnet": "10.89.0.8/24",
                                        "gateway": "10.89.0.1"
                                   }
                              ],
                              "mac_address": "7a:2c:0c:87:87:b0"
                         }
                    }
               },
               "e320cd74995da4daea23ba1053314f6c5088a1ca6dfcea45496d46cac0027cbe": {
                    "name": "nginx_webserver",
                    "interfaces": {
                         "eth0": {
                              "subnets": [
                                   {
                                        "ipnet": "10.89.0.47/24",
                                        "gateway": "10.89.0.1"
                                   }
                              ],
                              "mac_address": "de:b7:32:18:24:fc"
                         }
                    }
               },
               "ee0d0c8943acc265870e078aacaa821d0262e6a43f8a2e2ad4c3fdd14ac7bb95": {
                    "name": "midpoint-midpoint_data-1",
                    "interfaces": {
                         "eth0": {
                              "subnets": [
                                   {
                                        "ipnet": "10.89.0.6/24",
                                        "gateway": "10.89.0.1"
                                   }
                              ],
                              "mac_address": "92:92:9b:47:ae:aa"
                         }
                    }
               }
          }
     }
]
(base) 
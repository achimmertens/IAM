#!/bin/bash
# Automatische Aktualisierung der Container-IP-Adressen in Keycloak-Konfiguration

# Hole die aktuelle IP des LDAP-Servers
LDAP_IP=$(podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ldap_server)

# Beispiel: Keycloak-Konfiguration anpassen (hier als .env-Datei)
KEYCLOAK_CONFIG="/d/IAM/keycloak/keycloak.env"

if [ -n "$LDAP_IP" ]; then
    echo "LDAP_IP=$LDAP_IP" > "$KEYCLOAK_CONFIG"
    echo "Connection URL in Keycloak: ldap://$LDAP_IP:3389"
else
    echo "LDAP-Server läuft nicht oder IP konnte nicht ermittelt werden!"
fi

# Optional: Weitere Container-IPs automatisch eintragen
# MIDPOINT_IP=$(podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' midpoint_server)
# echo "MIDPOINT_IP=$MIDPOINT_IP" >> "$KEYCLOAK_CONFIG"

# Hinweis: Die Keycloak-Konfiguration muss so angepasst werden, dass sie die .env-Datei oder Umgebungsvariablen nutzt.
# Alternativ kann die IP direkt in die Keycloak-Konfigurationsdatei geschrieben werden (z.B. mit sed).

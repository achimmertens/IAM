#!/bin/bash

# --- Konfiguration ---
NETZWERK_NAME="sailpoint_net"
SUBNETZ="10.90.0.0/24"
FESTE_IP="10.90.0.10"
CONTAINER_NAME="Tomcat_Sailpoint"
TOMCAT_IMAGE="tomcat:latest"
PORT="8080"

# --- Netzwerk anlegen (sofern nicht vorhanden) ---
if ! podman network exists $NETZWERK_NAME; then
  podman network create \
    --subnet $SUBNETZ \
    $NETZWERK_NAME
  echo "Netzwerk $NETZWERK_NAME angelegt."
else
  echo "Netzwerk $NETZWERK_NAME existiert bereits."
fi

# --- Container löschen, falls schon vorhanden ---
# if podman ps -a --format '{{.Names}}' | grep -w $CONTAINER_NAME > /dev/null; then
#  podman rm -f $CONTAINER_NAME
#  echo "Alter Container $CONTAINER_NAME entfernt."
# fi

# --- Tomcat-Image holen ---
podman pull $TOMCAT_IMAGE

# --- Container starten ---
podman run -d \
    --name $CONTAINER_NAME \
    --network $NETZWERK_NAME \
    --ip $FESTE_IP \
    -p $PORT:8080 \
    $TOMCAT_IMAGE

echo "Tomcat-Container '$CONTAINER_NAME' mit IP $FESTE_IP wurde gestartet."
echo "Zugriff: http://localhost:$PORT oder http://$FESTE_IP:$PORT (je nach Netzwerkkonfiguration)"

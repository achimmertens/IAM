#!/bin/bash

# Netzwerk-Parameter
NETZWERK_NAME="sailpoint_net"
SUBNETZ="10.89.0.0/24"
FESTE_IP="10.89.0.20"

# Container-Parameter
CONTAINER_NAME="SQL_Sailpoint"
IMAGE_NAME="postgres:latest"
POSTGRES_USER="sailpoint"
POSTGRES_PASSWORD="supersecurepass"
POSTGRES_DB="sailpoint_db"
PORT="5432"

echo "[1/3] Erstelle Netzwerk $NETZWERK_NAME ..."
podman network create --subnet $SUBNETZ $NETZWERK_NAME

echo "[2/3] Starte PostgreSQL-Container $CONTAINER_NAME ..."
podman run -d \
  --name $CONTAINER_NAME \
  --network $NETZWERK_NAME \
  --ip $FESTE_IP \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=$POSTGRES_DB \
  -p $PORT:5432 \
  $IMAGE_NAME

echo "[3/3] Statusabfrage:"
podman ps -a --filter name=$CONTAINER_NAME

echo
echo "Fertig! Zugriff via:"
echo "Lokal im Container:"
echo "  podman exec -it $CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB"
echo
echo "Vom Host:"
echo "  psql -h localhost -U $POSTGRES_USER -d $POSTGRES_DB -p $PORT"
echo "Passwort: $POSTGRES_PASSWORD"

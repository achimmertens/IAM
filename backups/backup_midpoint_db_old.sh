#!/bin/bash
BACKUP_DIR="/d/IAM/backups"
BACKUP_FILE="midpoint_backup_$(date +%Y%m%d).sql"

# mkdir -p $BACKUP_DIR
# Backup erstellen
podman exec -i midpoint-midpoint_data-1 pg_dump \
  -U midpoint \
  -h localhost \
  -d midpoint \
  -W > $BACKUP_DIR/midpoint_backup_$(date +%Y%m%d).sql

ls -l $BACKUP_DIR
echo "Backup created: $BACKUP_DIR/$BACKUP_FILE"
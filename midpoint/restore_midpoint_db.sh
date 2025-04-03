#!/bin/bash
# filepath: d:\IAM\restore_midpoint_db.sh

# Variables
BACKUP_DIR="/d/IAM/backups"
BACKUP_FILE="midpoint_backup_20250401.sql"  # Replace with the correct backup file
ADMIN_BACKUP_FILE="midpoint_admin_backup_20250401.sql"  # Replace with the correct admin backup file

# Stop all containers
echo "Stopping all containers..."
podman compose down

# Wait for database to initialize
sleep 10

# Remove volumes to start fresh
echo "Removing volumes..."
podman volume rm midpoint_midpoint_home
podman volume rm midpoint_midpoint_data

# Start database container
echo "Starting database container..."
podman compose up midpoint_data -d

# Wait for database to initialize
sleep 10

# Restore the full database
echo "Restoring full database..."
PGPASSWORD=db.secret.pw.007 cat $BACKUP_DIR/$BACKUP_FILE | \
  podman exec -i midpoint-midpoint_data-1 psql -U midpoint -d midpoint

# echo "Restoring full database..."
PGPASSWORD=db.secret.pw.007 cat /d/IAM/backups/midpoint_backup_20250401.sql | \
 podman exec -i midpoint-midpoint_data-1 psql -U midpoint -d midpoint


# Restore administrator details
echo "Restoring administrator details..."
PGPASSWORD=db.secret.pw.007 podman exec -i midpoint-midpoint_data-1 \
  psql -U midpoint -d midpoint -c "
    COPY m_user (oid, nameorig, namenorm, fullobject, tenantreftargetoid, tenantreftargettype, tenantrefrelationid, lifecyclestate, cidseq, version, policysituations, subtypes, fulltextinfo, ext, creatorreftargetoid, creatorreftargettype, creatorrefrelationid, createchannelid, createtimestamp, modifierreftargetoid, modifierreftargettype, modifierrefrelationid, modifychannelid, modifytimestamp, db_created, db_modified, objecttype, costcenter, emailaddress, photo, locale, localityorig, localitynorm, preferredlanguage, telephonenumber, timezone, passwordcreatetimestamp, passwordmodifytimestamp, administrativestatus, effectivestatus, enabletimestamp, disabletimestamp, disablereason, validitystatus, validfrom, validto, validitychangetimestamp, archivetimestamp, lockoutstatus, normalizeddata, additionalnameorig, additionalnamenorm, employeenumber, familynameorig, familynamenorm, fullnameorig, fullnamenorm, givennameorig, givennamenorm, honorificprefixorig, honorificprefixnorm, honorificsuffixorig, honorificsuffixnorm, nicknameorig, nicknamenorm, personalnumber, titleorig, titlenorm, organizations, organizationunits)
    FROM STDIN WITH CSV HEADER;" < $BACKUP_DIR/$ADMIN_BACKUP_FILE

echo "Restoring administrator details..."
PGPASSWORD=db.secret.pw.007 podman exec -i midpoint-midpoint_data-1 \
  psql -U midpoint -d midpoint -c "
    COPY m_user (oid, nameorig, namenorm, fullobject, tenantreftargetoid, tenantreftargettype, tenantrefrelationid, lifecyclestate, cidseq, version, policysituations, subtypes, fulltextinfo, ext, creatorreftargetoid, creatorreftargettype, creatorrefrelationid, createchannelid, createtimestamp, modifierreftargetoid, modifierreftargettype, modifierrefrelationid, modifychannelid, modifytimestamp, db_created, db_modified, costcenter, emailaddress, photo, locale, localityorig, localitynorm, preferredlanguage, telephonenumber, timezone, passwordcreatetimestamp, passwordmodifytimestamp, administrativestatus, effectivestatus, enabletimestamp, disabletimestamp, disablereason, validitystatus, validfrom, validto, validitychangetimestamp, archivetimestamp, lockoutstatus, normalizeddata, additionalnameorig, additionalnamenorm, employeenumber, familynameorig, familynamenorm, fullnameorig, fullnamenorm, givennameorig, givennamenorm, honorificprefixorig, honorificprefixnorm, honorificsuffixorig, honorificsuffixnorm, nicknameorig, nicknamenorm, personalnumber, titleorig, titlenorm, organizations, organizationunits)
    FROM STDIN WITH CSV HEADER;" < /d/IAM/backups/midpoint_admin_backup_20250401.sql

COPY m_user (oid, nameorig, namenorm, fullobject, tenantreftargetoid, tenantreftargettype, tenantrefrelationid, lifecyclestate, cidseq, version, policysituations, subtypes, fulltextinfo, ext, creatorreftargetoid, creatorreftargettype, creatorrefrelationid, createchannelid, createtimestamp, modifierreftargetoid, modifierreftargettype, modifierrefrelationid, modifychannelid, modifytimestamp, db_created, db_modified, costcenter, emailaddress, photo, locale, localityorig, localitynorm, preferredlanguage, telephonenumber, timezone, passwordcreatetimestamp, passwordmodifytimestamp, administrativestatus, effectivestatus, enabletimestamp, disabletimestamp, disablereason, validitystatus, validfrom, validto, validitychangetimestamp, archivetimestamp, lockoutstatus, normalizeddata, additionalnameorig, additionalnamenorm, employeenumber, familynameorig, familynamenorm, fullnameorig, fullnamenorm, givennameorig, givennamenorm, honorificprefixorig, honorificprefixnorm, honorificsuffixorig, honorificsuffixnorm, nicknameorig, nicknamenorm, personalnumber, titleorig, titlenorm, organizations, organizationunits)
FROM '/d/IAM/backups/midpoint_admin_backup_20250401.sql' WITH CSV HEADER;


# Start all services
echo "Starting all services..."
podman compose up -d

# Monitor logs
podman logs -f midpoint-midpoint_server-1
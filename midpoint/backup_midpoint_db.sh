podman container export -o /d/IAM/backups/midpoint_container_backup.tar midpoint-midpoint_server-1
podman container export -o /d/IAM/backups/midpoint_container_backup.tar midpoint-midpoint_data-1
podman volume ls
$ podman volume inspect midpoint_midpoint_home | grep Mountpoint        
#          "Mountpoint": "/home/user/.local/share/containers/storage/volumes/midpoint_midpoint_home/_data",
# ←]633;P;Cwd=D:/Users/User/anaconda3/Library/d/IAM/midpoint(base)
# /home/user/.local/share/containers/storage/volumes/midpoint_midpoint_home/_data

podman volume export <volumename> --output /path/to/backup/volumename.tar
podman volume export midpoint-midpoint_data-1 --output /d/IAM/backups/midpoint_data_backup.tar
podman run -v midpoint-midpoint_data-1:/source:ro -v $(pwd):/backup alpine tar -czf /d/iam/backups/midpoint-midpoint_data-1-backup.tar.gz -C /source .
podman run -v midpoint_midpoint_data:/source:ro -v //d/IAM/midpoint/temp_backup:/backup alpine tar -czf /backup/midpoint_data_backup.tar.gz -C /source .
podman cp midpoint-midpoint_server-1:/var/lib/postgresql/data ./midpoint_data_backup

          "Mounts": [
               {
                    "Type": "volume",
                    "Name": "midpoint_midpoint_data",
                    "Source": "/home/user/.local/share/containers/storage/volumes/midpoint_midpoint_data/_data",
                    "Destination": "/var/lib/postgresql/data",

# Ein Backup, das funktioniert:
podman cp -a midpoint-midpoint_data-1:/var/lib/postgresql/data ./midpoint_data_backup


# Ein besseres Backup:
# Backup both database and keystore (both containers are running, but no data should be moved during backup)
podman cp -a midpoint-midpoint_data-1:/var/lib/postgresql/data ./midpoint_data_backup
podman cp -a midpoint-midpoint_server-1:/opt/midpoint/var/keystore.jceks ./keystore.jceks.backup

# And restore both during recovery


# Restore the database
# Direkt nach podman compose up 
podman stop midpoint-midpoint_server-1
podman stop midpoint-midpoint_data-1
podman compose up midpoint_restore
podman compose up

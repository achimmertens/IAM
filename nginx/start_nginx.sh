# Start Nginx server with network configuration and install diagnostic tools
# podman run -d --name nginx-webserver \
#  --network iam_network \
#  --mount type=bind,source=/d/IAM/nginx,target=/usr/share/nginx/html,readonly \
#  -p 8080:80 \
#  nginx:latest

# Install diagnostic tools
# podman exec -it nginx-webserver bash -c "apt-get update && apt-get install -y iputils-ping ldap-utils curl net-tools telnet"

# Start in interactive mode
podman start -a nginx-webserver


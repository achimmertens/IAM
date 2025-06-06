# Start Nginx server with network configuration
podman run --name nginx_webserver \
  --network midpoint_net \
  --dns 127.0.0.11 \
  --mount type=bind,source=/d/IAM/nginx/nginx.conf.new,target=/etc/nginx/nginx.conf,readonly \
  --mount type=bind,source=/d/IAM/nginx/sites-enabled,target=/etc/nginx/sites-enabled,readonly \
  --mount type=bind,source=/d/IAM/nginx,target=/usr/share/nginx/html,readonly \
  -p 8080:80 \
  nginx:latest

# Install diagnostic tools
# podman exec -it nginx_webserver bin/bash
# apt-get update && apt-get install -y curl


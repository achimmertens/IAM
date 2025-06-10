# Start Nginx server with network configuration
podman stop nginx_webserver || true
podman rm nginx_webserver || true

# Create required directories
mkdir -p /d/IAM/nginx/html
mkdir -p /d/IAM/nginx/logs

# Copy HTML files
cp -f /d/IAM/nginx/index.html /d/IAM/nginx/html/
cp -f /d/IAM/nginx/50x.html /d/IAM/nginx/html/

# Touch log files to ensure they exist
touch /d/IAM/nginx/logs/error.log
touch /d/IAM/nginx/logs/access.log

# Start the container
podman run --name nginx_webserver \
  --network midpoint_net \
  --dns 127.0.0.11 \
  --mount type=bind,source=/d/IAM/nginx/nginx.conf,target=/etc/nginx/nginx.conf,readonly \
  --mount type=bind,source=/d/IAM/nginx/sites-enabled,target=/etc/nginx/sites-enabled,readonly \
  --mount type=bind,source=/d/IAM/nginx/html,target=/usr/share/nginx/html \
  --mount type=bind,source=/d/IAM/nginx/logs,target=/var/log/nginx \
  -p 8080:80 \
  nginx:latest

# Install diagnostic tools
# podman exec -it nginx_webserver bin/bash
# apt-get update && apt-get install -y curl


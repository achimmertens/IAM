# Start Nginx server with network configuration
podman run --name nginx_webserver \
  --network iam_network \
  --mount type=bind,source=/d/IAM/nginx,target=/usr/share/nginx/html,readonly \
  --mount type=bind,source=/d/IAM/nginx/default.conf,target=/etc/nginx/conf.d/default.conf,readonly \
  -p 8080:80 \
  nginx:latest

# Install diagnostic tools
podman exec nginx_webserver /bin/sh -c "apt-get update && apt-get install -y curl"


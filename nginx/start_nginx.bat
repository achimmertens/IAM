# podman run -d --name nginx-webserver --mount type=bind,source=/d/IAM/nginx,target=/usr/share/nginx/html,readonly -p 8080:80 nginx:latest
podman start -a nginx-webserver
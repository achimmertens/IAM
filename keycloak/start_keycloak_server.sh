# podman run -p 8081:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin --name keycloak_server quay.io/keycloak/keycloak:21.0.2 start-dev
podman start -a keycloak_server
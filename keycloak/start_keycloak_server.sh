# Start Keycloak server with network configuration
podman run -p 8081:8080 \
  --network iam_network \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_PROXY=edge \
  -e KC_HOSTNAME_STRICT=false \
  -e KC_HOSTNAME_STRICT_HTTPS=false \
  -e KC_HOSTNAME=localhost:8081 \
  --name keycloak_server \
  quay.io/keycloak/keycloak:21.0.2 \
  start-dev
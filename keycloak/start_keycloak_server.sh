# Start Keycloak server with network configuration
podman run -p 8081:8080 \
  --network iam_network \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  --name keycloak_server \
  quay.io/keycloak/keycloak:21.0.2 \
  start-dev --hostname-strict=false --hostname-strict-https=false

  # podman inspect ldap_server --format '{{.NetworkSettings.Networks.iam_network.IPAddress}}'
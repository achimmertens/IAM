# Start Keycloak server with network configuration
# podman stop keycloak_server && \
# podman rm keycloak_server && \
# podman run -p 8081:8080 \
#    --network midpoint_net \
#    -e KEYCLOAK_ADMIN=admin \
#    -e KEYCLOAK_ADMIN_PASSWORD=admin \
#    -e KC_PROXY=edge \
#    -e KC_HOSTNAME_STRICT=false \
#    -e KC_HOSTNAME_STRICT_HTTPS=false \
#    -e KC_LOG_LEVEL=DEBUG \
#    --name keycloak_server \
#    quay.io/keycloak/keycloak:21.0.2 \
#    start-dev
podman start keycloak_server -a
bash d:/IAM/update_container_ips.sh
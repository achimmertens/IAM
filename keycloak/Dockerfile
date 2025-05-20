# Use Red Hat UBI 9 as base
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Install Keycloak and diagnostic tools
RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs -y install \
    iputils \
    openldap-clients \
    nc \
    java-17-openjdk-headless \
    tar \
    curl \
    && microdnf clean all

# Download and install Keycloak
RUN curl -L -o /tmp/keycloak.tar.gz https://github.com/keycloak/keycloak/releases/download/21.0.2/keycloak-21.0.2.tar.gz \
    && tar -xzf /tmp/keycloak.tar.gz -C /opt \
    && mv /opt/keycloak-* /opt/keycloak \
    && rm /tmp/keycloak.tar.gz

EXPOSE 8080
EXPOSE 8443

ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev", "--hostname-strict=false", "--hostname-strict-https=false"]

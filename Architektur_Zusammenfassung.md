# IAM System Architecture Summary

This document outlines the architecture of the Identity and Access Management (IAM) system.

## Services and Endpoints

The system consists of four main services running in Podman containers:

-   **Nginx (Reverse Proxy):** `http://localhost:8080`
-   **Keycloak (Identity Provider):** `http://localhost:8081`
-   **Midpoint (Identity Governance):** `http://localhost:8082`
-   **OpenLDAP (User Directory):** `ldap://localhost:3389`

All services are launched together using the "Start All Services" task in VS Code.

## User Provisioning Flow

User accounts are managed through the following automated process:

1.  **Data Source:** User data is maintained in a CSV file located at `midpoint/hr.csv`.
2.  **Import:** Midpoint is configured to periodically read this CSV file. The mapping of CSV columns to user attributes is defined in `midpoint/resource-csv-hr.xml`, and the import schedule is defined in `midpoint/task-hr-import.xml`.
3.  **Provisioning:** After importing the users, Midpoint provisions them into the OpenLDAP directory. This synchronization ensures that the LDAP server always contains the current set of users.

## Authentication Flow

The authentication process for accessing a protected web resource is as follows:

1.  **Request:** A user attempts to access a resource protected by the Nginx reverse proxy.
2.  **Delegation:** Nginx, using its OAuth2/OIDC client capabilities, redirects the user to Keycloak for authentication. This is configured in `nginx/nginx.conf` and `nginx/sites-enabled/default.conf`.
3.  **Authentication:** Keycloak presents a login page to the user. Keycloak is configured with a "User Federation" to the OpenLDAP server, meaning it uses LDAP as its backend user store.
4.  **Validation:** The user enters their credentials, which Keycloak validates against the user data in the LDAP directory.
5.  **Token Issuance:** Upon successful authentication, Keycloak issues a JWT (JSON Web Token) to the user's browser.
6.  **Access Grant:** The browser sends the JWT back to Nginx, which validates the token. If the token is valid, Nginx grants access to the originally requested resource.

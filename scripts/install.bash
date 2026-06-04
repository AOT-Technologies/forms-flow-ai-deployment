#!/bin/bash

# Function to set the appropriate Docker Compose file based on the architecture
set_docker_compose_file() {
    docker_compose_file='docker-compose.yml'
    if [ "$(uname -m)" == "arm64" ]; then
        docker_compose_file='docker-compose-arm64.yml'
    fi
}

# Function to check for the appropriate Docker Compose command
set_compose_command() {
    if command -v docker compose &> /dev/null; then
        compose_cmd="docker compose"
    elif command -v docker-compose &> /dev/null; then
        compose_cmd="docker-compose"
    else
        echo "Neither 'docker compose' nor 'docker-compose' is installed. Please install Docker Compose to continue."
        exit 1
    fi
    echo "Using $compose_cmd for managing containers."
}

fetch_valid_versions() {
    valid_versions_url="https://forms-flow-docker-versions.s3.ca-central-1.amazonaws.com/tested_versions.json"
    validVersions=$(curl -s "$valid_versions_url")
    if [ -z "$validVersions" ]; then
        echo "Failed to fetch the list of valid Docker versions from $valid_versions_url"
        exit 1
    fi
    echo "Fetched valid Docker versions successfully."

    # Run the docker -v command and capture its output
    docker_info=$(docker -v 2>&1)

    # Extract the Docker version using string manipulation
    docker_version=$(echo "$docker_info" | awk '{print $3}' | tr -d ,)

    # Display the extracted Docker version
    echo "Docker version: $docker_version"
}

check_valid_version() {
  if echo "$validVersions" | grep -q "\"$docker_version\""; then
     echo "Your Docker version $docker_version is tested and working!"
  else
     echo "This Docker version is not tested!"
     read -p "Do you want to continue? [y/n]: " continue
     if [ "$continue" != "y" ]; then
        exit
     fi
  fi
}

# Function to check if the web API is up
isUp() {
    while true; do
        HTTP=$(curl -LI "http://$ip_add:5001" -o /dev/null -w "%{http_code}" -s)
        if [ "$HTTP" == "200" ]; then
            echo "formsflow.ai is successfully installed."
            exit 0
        else
            echo "Finishing setup."
            sleep 6
        fi
    done
}

# Function to find the IPv4 address
find_my_ip() {
   # ipadd=$(hostname -I | awk '{print $1}')
    if [ "$(uname)" = "Darwin" ]; then
        ipadd=$(ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
    elif [ "$(uname)" = "Linux" ]; then
        ipadd=$(hostname -I | awk '{print $1}')
    fi
    ip_add=$ipadd
    read -p "Confirm that your IPv4 address is $ip_add? [y/n]: " choice
    if [ "$choice" != "y" ]; then
        read -p "What is your IPv4 address? " ip_add
    fi
}

# Fuction to ask prompt questions
prompt_question() {
    # Ask about analytics installation
    read -p "Do you want analytics to include in the installation? [y/n]: " choice
    if [ "$choice" == "y" ]; then
        analytics=1
    else
        analytics=0
    fi
    # Export variables to make them available in the main function
    export analytics
}


# Function to set common properties
set_common_properties() {
    WEBSOCKET_ENCRYPT_KEY="giert989jkwrgb@DR55"
    KEYCLOAK_BPM_CLIENT_SECRET="e4bdbd25-1467-4f7f-b993-bc4b1944c943"
    export WEBSOCKET_ENCRYPT_KEY
    export KEYCLOAK_BPM_CLIENT_SECRET
}

# Function to start Keycloak
keycloak() {
    cd ../docker-compose/
    if [ -f "$1/.env" ]; then
        rm "$1/.env"
    fi
    echo KEYCLOAK_START_MODE=start-dev >> .env
    $compose_cmd -p formsflow-ai -f "$1/$docker_compose_file" up --build -d keycloak
    sleep 5
    KEYCLOAK_URL="http://$ip_add:8080"
    export KEYCLOAK_URL
}

# Function to start forms-flow-forms
forms_flow_forms() {
    FORMIO_DEFAULT_PROJECT_URL="http://$ip_add:3001"
    echo "FORMIO_DEFAULT_PROJECT_URL=$FORMIO_DEFAULT_PROJECT_URL" >> "$1/.env"
    $compose_cmd -p formsflow-ai -f "$1/$docker_compose_file" up --build -d forms-flow-forms
    sleep 5
}

# Function to start forms-flow-web
forms_flow_web() {
    BPM_API_URL="http://$ip_add:8000/camunda"
    GRAPHQL_API_URL="http://$ip_add:5500/queries"
    echo "GRAPHQL_API_URL=$GRAPHQL_API_URL" >> "$1/.env"
    echo "BPM_API_URL=$BPM_API_URL" >> "$1/.env"
    $compose_cmd -p formsflow-ai -f "$1/$docker_compose_file" up --build -d forms-flow-web
}

# Function to start forms-flow-bpm
forms_flow_bpm() {
    FORMSFLOW_API_URL="http://$ip_add:5001"
    WEBSOCKET_SECURITY_ORIGIN="http://$ip_add:3000"
    SESSION_COOKIE_SECURE="false"
    KEYCLOAK_WEB_CLIENTID="forms-flow-web"
    REDIS_URL="redis://$ip_add:6379/0"
    KEYCLOAK_URL_HTTP_RELATIVE_PATH="/auth"
    FORMSFLOW_DOC_API_URL="http://$ip_add:5006"
    DATA_ANALYSIS_URL="http://$ip_add:6001"
    USER_NAME_DISPLAY_CLAIM="preferred_username"



    echo "FORMSFLOW_API_URL=$FORMSFLOW_API_URL" >> "$1/.env"
    echo "WEBSOCKET_SECURITY_ORIGIN=$WEBSOCKET_SECURITY_ORIGIN" >> "$1/.env"
    echo "SESSION_COOKIE_SECURE=$SESSION_COOKIE_SECURE" >> "$1/.env"
    echo "KEYCLOAK_WEB_CLIENTID=$KEYCLOAK_WEB_CLIENTID" >> "$1/.env"
    echo "REDIS_URL=$REDIS_URL" >> "$1/.env"
    echo "FORMSFLOW_DOC_API_URL=$FORMSFLOW_DOC_API_URL" >> "$1/.env"
    echo "KEYCLOAK_URL_HTTP_RELATIVE_PATH=$KEYCLOAK_URL_HTTP_RELATIVE_PATH" >> "$1/.env"
    echo "DATA_ANALYSIS_URL=$DATA_ANALYSIS_URL" >> "$1/.env"
    echo "USER_NAME_DISPLAY_CLAIM=$USER_NAME_DISPLAY_CLAIM" >> "$1/.env"
    $compose_cmd -p formsflow-ai -f "$1/$docker_compose_file" up --build -d forms-flow-bpm
    sleep 6
}

# Function to start forms-flow-analytics
forms_flow_analytics() {
    REDASH_HOST="http://$ip_add:7001"
    PYTHONUNBUFFERED="0"
    REDASH_LOG_LEVEL="INFO"
    REDASH_REDIS_URL="redis://redis:6379/0"
    POSTGRES_USER="postgres"
    POSTGRES_PASSWORD="changeme"
    POSTGRES_DB="postgres"
    REDASH_COOKIE_SECRET="redash-selfhosted"
    REDASH_SECRET_KEY="redash-selfhosted"
    REDASH_DATABASE_URL="postgresql://postgres:changeme@postgres/postgres"
    REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN="*"
    REDASH_REFERRER_POLICY="no-referrer-when-downgrade"
    REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS="Content-Type, Authorization"
    echo "REDASH_HOST=$REDASH_HOST" >> "$1/.env"
    echo "PYTHONUNBUFFERED=$PYTHONUNBUFFERED" >> "$1/.env"
    echo "REDASH_LOG_LEVEL=$REDASH_LOG_LEVEL" >> "$1/.env"
    echo "REDASH_REDIS_URL=$REDASH_REDIS_URL" >> "$1/.env"
    echo "POSTGRES_USER=$POSTGRES_USER" >> "$1/.env"
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> "$1/.env"
    echo "POSTGRES_DB=$POSTGRES_DB" >> "$1/.env"
    echo "REDASH_COOKIE_SECRET=$REDASH_COOKIE_SECRET" >> "$1/.env"
    echo "REDASH_SECRET_KEY=$REDASH_SECRET_KEY" >> "$1/.env"
    echo "REDASH_DATABASE_URL=$REDASH_DATABASE_URL" >> "$1/.env"
    echo "REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN=$REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN" >> "$1/.env"
    echo "REDASH_REFERRER_POLICY=$REDASH_REFERRER_POLICY" >> "$1/.env"
    echo "REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS=$REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS" >> "$1/.env"
    $compose_cmd -p formsflow-ai -f "$1/analytics-docker-compose.yml" run --rm server create_db
    $compose_cmd -p formsflow-ai -f "$1/analytics-docker-compose.yml" up --build -d
    sleep 5
}

# Function to start forms-flow-webapi
forms_flow_api() {
    WEB_BASE_URL="http://$ip_add:3000"
    FORMSFLOW_ADMIN_URL="http://$ip_add:5010/api/v1"
    if [ "$2" == "1" ]; then
        echo "Analytics is included in the installation."
        read -p "What is your Redash API key? " INSIGHT_API_KEY
        INSIGHT_API_URL="http://$ip_add:7001"
        echo "INSIGHT_API_URL=$INSIGHT_API_URL" >> "$1/.env"
        echo "INSIGHT_API_KEY=$INSIGHT_API_KEY" >> "$1/.env"
    fi
    echo "WEB_BASE_URL=$WEB_BASE_URL" >> "$1/.env"
    echo "FORMSFLOW_ADMIN_URL=$FORMSFLOW_ADMIN_URL" >> "$1/.env"
    $compose_cmd -p formsflow-ai -f "$1/$docker_compose_file" up --build -d forms-flow-webapi
}

# Function to start forms-flow-documents-api
forms_flow_documents() {
    DOCUMENT_SERVICE_URL="http://$ip_add:5006"
    echo "DOCUMENT_SERVICE_URL=$DOCUMENT_SERVICE_URL" >> "$1/.env"
    $compose_cmd -p formsflow-ai -f "$1/$docker_compose_file" up --build -d forms-flow-documents-api
    sleep 5
}
forms_flow_data_layer() {
    DEBUG=false
    FORMSFLOW_DATA_LAYER_WORKERS=4
    FORMSFLOW_DATALAYER_CORS_ORIGINS=*
    KEYCLOAK_ENABLE_CLIENT_AUTH=false
    KEYCLOAK_URL_REALM=forms-flow-ai
    JWT_OIDC_JWKS_URI=http://$ip_add:8080/auth/realms/forms-flow-ai/protocol/openid-connect/certs
    JWT_OIDC_ISSUER=http://$ip_add:8080/auth/realms/forms-flow-ai
    JWT_OIDC_AUDIENCE=forms-flow-web
    JWT_OIDC_CACHING_ENABLED=True
    FORMSFLOW_API_DB_URL=postgresql://postgres:changeme@$ip_add:6432/webapi
    FORMSFLOW_API_DB_HOST=$ip_add
    FORMSFLOW_API_DB_PORT=6432
    FORMSFLOW_API_DB_USER=postgres
    FORMSFLOW_API_DB_PASSWORD=changeme
    FORMSFLOW_API_DB_NAME=webapi
    FORMIO_DB_HOST=$ip_add
    FORMIO_DB_PORT=27018
    FORMIO_DB_USERNAME=admin
    FORMIO_DB_PASSWORD=changeme
    FORMIO_DB_NAME=formio
    FORMIO_DB_URI="mongodb://admin:changeme@$ip_add:27018/formio?authMechanism=SCRAM-SHA-1&authSource=admin"
    CAMUNDA_DB_URL=jdbc:postgresql://admin:changeme@$ip_add:5432/formsflow-bpm
    CAMUNDA_DB_USER=admin
    CAMUNDA_DB_PASSWORD=changeme
    CAMUNDA_DB_HOST=$ip_add
    CAMUNDA_DB_PORT=5432
    CAMUNDA_DB_NAME=formsflow-bpm

    echo "DEBUG=$DEBUG" >> "$1/.env"
    echo "FORMSFLOW_DATA_LAYER_WORKERS=$FORMSFLOW_DATA_LAYER_WORKERS" >> "$1/.env"
    echo "FORMSFLOW_DATALAYER_CORS_ORIGINS=$FORMSFLOW_DATALAYER_CORS_ORIGINS" >> "$1/.env"
    echo "KEYCLOAK_ENABLE_CLIENT_AUTH=$KEYCLOAK_ENABLE_CLIENT_AUTH" >> "$1/.env"
    echo "KEYCLOAK_URL_REALM=$KEYCLOAK_URL_REALM" >> "$1/.env"
    echo "JWT_OIDC_JWKS_URI=$JWT_OIDC_JWKS_URI" >> "$1/.env"
    echo "JWT_OIDC_ISSUER=$JWT_OIDC_ISSUER" >> "$1/.env"
    echo "JWT_OIDC_AUDIENCE=$JWT_OIDC_AUDIENCE" >> "$1/.env"
    echo "JWT_OIDC_CACHING_ENABLED=$JWT_OIDC_CACHING_ENABLED" >> "$1/.env"
    echo "FORMSFLOW_API_DB_URL=$FORMSFLOW_API_DB_URL" >> "$1/.env"
    echo "FORMSFLOW_API_DB_HOST=$FORMSFLOW_API_DB_HOST" >> "$1/.env"
    echo "FORMSFLOW_API_DB_PORT=$FORMSFLOW_API_DB_PORT" >> "$1/.env"
    echo "FORMSFLOW_API_DB_USER=$FORMSFLOW_API_DB_USER" >> "$1/.env"
    echo "FORMSFLOW_API_DB_PASSWORD=$FORMSFLOW_API_DB_PASSWORD" >> "$1/.env"
    echo "FORMSFLOW_API_DB_NAME=$FORMSFLOW_API_DB_NAME" >> "$1/.env"
    echo "FORMIO_DB_URI=$FORMIO_DB_URI" >> "$1/.env"
    echo "FORMIO_DB_HOST=$FORMIO_DB_HOST" >> "$1/.env"
    echo "FORMIO_DB_PORT=$FORMIO_DB_PORT" >> "$1/.env"
    echo "FORMIO_DB_USERNAME=$FORMIO_DB_USERNAME" >> "$1/.env"
    echo "FORMIO_DB_PASSWORD=$FORMIO_DB_PASSWORD" >> "$1/.env"
    echo "FORMIO_DB_NAME=$FORMIO_DB_NAME" >> "$1/.env"
    echo "FORMIO_DB_OPTIONS=$FORMIO_DB_OPTIONS" >> "$1/.env"
    echo "CAMUNDA_DB_URL=$CAMUNDA_DB_URL" >> "$1/.env"
    echo "CAMUNDA_DB_USER=$CAMUNDA_DB_USER" >> "$1/.env"
    echo "CAMUNDA_DB_PASSWORD=$CAMUNDA_DB_PASSWORD" >> "$1/.env"
    echo "CAMUNDA_DB_HOST=$CAMUNDA_DB_HOST" >> "$1/.env"
    echo "CAMUNDA_DB_PORT=$CAMUNDA_DB_PORT" >> "$1/.env"
    echo "CAMUNDA_DB_NAME=$CAMUNDA_DB_NAME" >> "$1/.env"
    $compose_cmd -p formsflow-ai -f "$1/$docker_compose_file" up --build -d forms-flow-data-layer
    sleep 5
}


# Main function
main() {
    set_common_properties
    set_docker_compose_file
    set_compose_command
    fetch_valid_versions
    check_valid_version
    find_my_ip
    prompt_question
    keycloak "$1"
    forms_flow_forms "$1"
    forms_flow_bpm "$1"
    if [ "$analytics" -eq 1 ]; then
        forms_flow_analytics "$1"
    fi
    forms_flow_api "$1" "$analytics"
    forms_flow_data_layer "$1"
    forms_flow_documents "$1"
    forms_flow_web "$1"
    isUp
    echo "********************** formsflow.ai is successfully installed ****************************"
    exit 0
}

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed or not running. Please install and start Docker before running this script."
    exit 1
fi

main "."

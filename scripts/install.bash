#!/bin/bash
ipadd=$(hostname -i)
echo "Do you wish to continue installation that include ANALYTICS? [y/n]" 
read choice
if [[ $choice == "y" ]]; then
    ANALYTICS=1
elif [[ $choice == "n" ]]; then
    ANALYTICS=0
fi

#############################################################
######################### main function #####################
#############################################################

function main
{
  keycloak
  if [[ $ANALYTICS == 1 ]]; then
    forms-flow-analytics
  elif [[ $ANALYTICS == 0 ]]; then
    forms-flow-bpm
  fi
  forms-flow-api
  forms-flow-forms
  installconfig
  forms-flow-web
}

#############################################################
######################## creating config.js #################
#############################################################

function installconfig
{
   cd ..
   if [[ -f config.js ]]; then
     rm config.js
   window["_env_"] = "{"
   NODE_ENV= "production",
   REACT_APP_API_SERVER_URL="http://$ipadd:3001",
   REACT_APP_API_PROJECT_URL="http://$ipadd:3001",
   REACT_APP_KEYCLOAK_CLIENT="forms-flow-web",
   REACT_APP_KEYCLOAK_URL_REALM="forms-flow-ai",
   REACT_APP_KEYCLOAK_URL="http://$ipadd:8080",
   REACT_APP_WEB_BASE_URL="http://$ipadd:5000",
   REACT_APP_CAMUNDA_API_URI="http://$ipadd:8000/camunda",
   REACT_APP_WEBSOCKET_ENCRYPT_KEY="giert989jkwrgb@DR55",
   REACT_APP_APPLICATION_NAME="formsflow.ai",
   REACT_APP_WEB_BASE_CUSTOM_URL="",
   REACT_APP_FORMIO_JWT_SECRET="--- change me now ---",
   REACT_APP_USER_ACCESS_PERMISSIONS={accessAllowApplications:false, accessAllowSubmissions:false}
	
   echo window["_env_"] = "{">>config.js
   echo NODE_ENV:%NODE_ENV%>>config.js
   echo REACT_APP_API_SERVER_URL:$REACT_APP_API_SERVER_URL>>config.js
   echo REACT_APP_API_PROJECT_URL:$REACT_APP_API_PROJECT_URL>>config.js
   echo REACT_APP_KEYCLOAK_CLIENT:$REACT_APP_KEYCLOAK_CLIENT>>config.js
   echo REACT_APP_KEYCLOAK_URL_REALM:$REACT_APP_KEYCLOAK_URL_REALM>>config.js
   echo REACT_APP_KEYCLOAK_URL:$REACT_APP_KEYCLOAK_URL>>config.js
   echo REACT_APP_WEB_BASE_URL:$REACT_APP_WEB_BASE_URL>>config.js
   echo REACT_APP_CAMUNDA_API_URI:$REACT_APP_CAMUNDA_API_URI>>config.js
   echo REACT_APP_WEBSOCKET_ENCRYPT_KEY:$REACT_APP_WEBSOCKET_ENCRYPT_KEY>>config.js
   echo REACT_APP_APPLICATION_NAME:$REACT_APP_APPLICATION_NAME>>config.js
   echo REACT_APP_WEB_BASE_CUSTOM_URL:$REACT_APP_WEB_BASE_CUSTOM_URL>>config.js
   echo REACT_APP_FORMIO_JWT_SECRET:$REACT_APP_FORMIO_JWT_SECRET>>config.js
   echo REACT_APP_USER_ACCESS_PERMISSIONS:$REACT_APP_USER_ACCESS_PERMISSIONS>>config.js
   echo "}";>>config.js
}

#############################################################
###################### forms-flow-Analytics #################
#############################################################

function forms-flow-analytics
{
    cd ../forms-flow-analytics/
    REDASH_HOST=http://$ipadd:7000
    PYTHONUNBUFFERED=0
    REDASH_LOG_LEVEL=INFO
    REDASH_REDIS_URL=redis://redis:6379/0
    POSTGRES_USER=postgres
    POSTGRES_PASSWORD=changeme
    POSTGRES_DB=postgres
    REDASH_COOKIE_SECRET=redash-selfhosted
    REDASH_SECRET_KEY=redash-selfhosted
    REDASH_DATABASE_URL=postgresql://postgres:changeme@postgres/postgres
    REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN=*
    REDASH_REFERRER_POLICY=no-referrer-when-downgrade
    REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS=Content-Type, Authorization
    echo REDASH_HOST=$REDASH_HOST>>.env
    echo PYTHONUNBUFFERED=$PYTHONUNBUFFERED>>.env
    echo REDASH_LOG_LEVEL=$REDASH_LOG_LEVEL>>.env
    echo REDASH_REDIS_URL=$REDASH_REDIS_URL>>.env
    echo POSTGRES_USER=$POSTGRES_USER>>.env
    echo POSTGRES_PASSWORD=$POSTGRES_PASSWORD>>.env
    echo POSTGRES_DB=$POSTGRES_DB>>.env
    echo REDASH_COOKIE_SECRET=$REDASH_COOKIE_SECRET>>.env
    echo REDASH_SECRET_KEY=$REDASH_SECRET_KEY>>.env
    echo REDASH_DATABASE_URL=$REDASH_DATABASE_URL>>.env
    echo REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN=$REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN>>.env
    echo REDASH_REFERRER_POLICY=$REDASH_REFERRER_POLICY>>.env
    echo REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS=$REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS>>.env

    docker-compose -f analytics-docker-compose.yml run --rm server create_db
    docker-compose -f analytics-docker-compose.yml up --build -d
}

#############################################################
######################## forms-flow-bpm #####################
#############################################################

function forms-flow-bpm
{
    cd ..
    ipadd=$(hostname -i)

    FORMSFLOW_API_URL=http://$ipadd:5000
    WEBSOCKET_SECURITY_ORIGIN=http://$ipadd:3000
    FORMIO_DEFAULT_PROJECT_URL=http://$ipadd:3001
	  WEBSOCKET_ENCRYPT_KEY=giert989jkwrgb@DR55

    echo KEYCLOAK_URL=$KEYCLOAK_URL>>.env
    echo KEYCLOAK_BPM_CLIENT_SECRET=$KEYCLOAK_BPM_CLIENT_SECRET%>>.env
    echo KEYCLOAK_URL_REALM=$KEYCLOAK_URL_REALM>>.env
    echo FORMSFLOW_API_URL=$FORMSFLOW_API_URL>>.env
    echo WEBSOCKET_SECURITY_ORIGIN=$WEBSOCKET_SECURITY_ORIGIN>>.env
    echo WEBSOCKET_ENCRYPT_KEY=$WEBSOCKET_ENCRYPT_KEY>>.env
    echo FORMIO_DEFAULT_PROJECT_URL=$FORMIO_DEFAULT_PROJECT_URL>>.env
    docker-compose -f docker-compose-local.yml up --build -d forms-flow-bpm
}

#############################################################
######################## forms-flow-webapi ##################
#############################################################

function forms-flow-api
{
    ipadd=$(hostname -i)
    FORMSFLOW_API_URL=http://$ipadd:5000
    CAMUNDA_API_URL=http://$ipadd:8000/camunda
    FORMSFLOW_API_CORS_ORIGINS=*
    if [[ $ANALYTICS == 1 ]]; then (
        echo What is your Redash API key?
        read INSIGHT_API_KEY
        INSIGHT_API_URL=http://$ipadd:7000
    )
    echo KEYCLOAK_URL=$KEYCLOAK_URL>>.env
    echo KEYCLOAK_BPM_CLIENT_SECRET=$KEYCLOAK_BPM_CLIENT_SECRET>>.env
    echo KEYCLOAK_URL_REALM=$KEYCLOAK_URL_REALM>>.env
    echo KEYCLOAK_ADMIN_USERNAME=$KEYCLOAK_ADMIN_USERNAME>>.env
    echo KEYCLOAK_ADMIN_PASSWORD=$KEYCLOAK_ADMIN_PASSWORD>>.env
    echo CAMUNDA_API_URL=$CAMUNDA_API_URL>>.env
    echo FORMSFLOW_API_CORS_ORIGINS=$FORMSFLOW_API_CORS_ORIGINS>>.env
    if [[ $ANALYTICS == 1 ]]; then ( 
        echo INSIGHT_API_URL=$INSIGHT_API_URL>>.env
        echo INSIGHT_API_KEY=$INSIGHT_API_KEY>>.env
    )
    echo FORMSFLOW_API_URL=$FORMSFLOW_API_URL>>.env
    docker-compose -f docker-compose-local.yml up --build -d forms-flow-webapi
}

#############################################################
######################## forms-flow-forms ###################
#############################################################

function forms-flow-forms
{
    ipadd=$(hostname -i)
    FORMIO_ROOT_EMAIL=admin@example.com
    FORMIO_ROOT_PASSWORD=changeme
    FORMIO_DEFAULT_PROJECT_URL=http://$ipadd:3001

    echo FORMIO_ROOT_EMAIL=$FORMIO_ROOT_EMAIL>>.env
    echo FORMIO_ROOT_PASSWORD=$FORMIO_ROOT_PASSWORD>>.env
    echo FORMIO_DEFAULT_PROJECT_URL=$FORMIO_DEFAULT_PROJECT_URL>>.env

    docker-compose -f docker-compose-local.yml up --build -d forms-flow-forms
    sleep 20
    fetch-role-ids

:restart-forms-service
   
    docker stop forms-flow-forms
    docker rm forms-flow-forms
    docker-compose -f docker-compose-local.yml up --build -d forms-flow-forms
}
function forms-flow-web
{
docker-compose -f docker-compose-local.yml up --build -d forms-flow-web
echo "********************** formsflow.ai is successfully installed ****************************"
}

#############################################################
########################### Keycloak ########################
#############################################################

function keycloak
{
    cd configuration/keycloak/
	if [[ -f .env ]]; then
     rm .env
    echo "Do you have an exsisting keycloak? [y/n]" 
    read value1
    function defaultinstallation
    {
        echo WE ARE SETING UP OUR DEFAULT KEYCLOCK FOR YOU
        printf "%s " "Press enter to continue"
        read that
        ipadd=$(hostname -i)
        echo Please wait, keycloak is setting up!
        docker-compose up -d
        KEYCLOAK_URL_REALM=forms-flow-ai
        KEYCLOAK_URL=http://{your-ip-address}:8080
        KEYCLOAK_URL=http://$ipadd:8080
        echo What is your [Keycloak] forms-flow-bpm client secret key?
        read KEYCLOAK_BPM_CLIENT_SECRET

        printf "%s " "Press enter to continue"
        read that
    }
    
    function INSTALL_WITH_EXISTING_KEYCLOAK
    {
      echo What is your Keycloak url?
      read KEYCLOAK_URL
      echo What is your keycloak url realm name?
      read KEYCLOAK_URL_REALM
	  echo what is your keycloak admin user name?
      read KEYCLOAK_ADMIN_USERNAME
	  echo what is your keycloak admin password?
      read KEYCLOAK_ADMIN_PASSWORD
    }
    
     if [[ "$value1" == "y" ]]; then  
        INSTALL_WITH_EXISTING_KEYCLOAK
     elif [[ "$value1" == "n" ]]; then  
         defaultinstallation
     fi  
}
function orderwithanalytics
{
  echo installation will be completed in the following order:
  echo 1. keycloak
  echo 2. analytics
  echo 3. Camunda
  echo 4. webapi
  echo 5. forms
  echo 6. web
  printf "%s " "Press enter to continue"
  read that
  main
}
function withoutanalytics
{
  echo installation will be completed in the following order:
  echo 1. keycloak
  echo 2. Camunda
  echo 3. webapi
  echo 4. forms
  echo 5. web 
  printf "%s " "Press enter to continue"
  read that
  main
}
if [[ $ANALYTICS == 1 ]]; then
    orderwithanalytics
elif [[ $ANALYTICS == 0 ]]; then
    withoutanalytics
fi

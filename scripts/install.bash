#!/bin/bash
ipadd=$(hostname -I | awk '{print $1}')
webapi_port=5000
if [ "$(uname)" == "Darwin" ]; then
    ipadd=$(ipconfig getifaddr en0)
    webapi_port=5001
fi

docker_compose_file='docker-compose.yml'
if [ "$(uname -m)" == "arm64" ]; then
    docker_compose_file='docker-compose-arm64.yml'
fi


echo "Do you wish to continue installation that include ANALYTICS? [y/n]" 
read choice
if [[ $choice == "y" ]]; then
    ANALYTICS=1
elif [[ $choice == "n" ]]; then
    ANALYTICS=0
fi
echo "Confirm that your IPv4 address is $ipadd [y/n]"
read choice
if [[ $choice == "y" ]]; then
    ipadd=$ipadd
    echo "$ipadd"
elif [[ $choice == "n" ]]; then
    read -p "Enter your IP Adress: " ipadd
    echo "$ipadd"
fi

KEYCLOAK_BPM_CLIENT_SECRET="e4bdbd25-1467-4f7f-b993-bc4b1944c943"
KEYCLOAK_URL="http://$ipadd:8080"
KEYCLOAK_URL_REALM="forms-flow-ai"

#############################################################
######################### main function #####################
#############################################################

function main
{
  keycloak
  if [[ $ANALYTICS == 1 ]]; then
    formsFlowAnalytics
    formsFlowForms
  elif [[ $ANALYTICS == 0 ]]; then
    formsFlowForms
  fi

  formsFlowBpm
  installconfig
  formsFlowApi
  formsFlowWeb
}

function isUp
{
    # Check if the web api is up
    api_status="$(curl -LI http://$ipadd:$webapi_port -o /dev/null -w '%{http_code}\n' -s)"
    if [[ $api_status == 200 ]]; then
        echo "********************** formsflow.ai is successfully installed ****************************"
    else
        echo "Finishing setup"
        sleep 5
        isUp
    fi

}

#############################################################
######################## creating config.js #################
#############################################################

function installconfig
{
   cd configuration/
   pwd
   if [[ -f config.js ]]; then
     rm config.js
   fi

   NODE_ENV="production"
   REACT_APP_API_SERVER_URL="http://$ipadd:3001"
   REACT_APP_API_PROJECT_URL="http://$ipadd:3001"
   REACT_APP_KEYCLOAK_CLIENT="forms-flow-web"
   REACT_APP_KEYCLOAK_URL_REALM="forms-flow-ai"
   REACT_APP_KEYCLOAK_URL="http://$ipadd:8080"
   REACT_APP_WEB_BASE_URL="http://$ipadd:$webapi_port"
   REACT_APP_BPM_URL="http://$ipadd:8000/camunda"
   REACT_APP_WEBSOCKET_ENCRYPT_KEY="giert989jkwrgb@DR55"
   REACT_APP_APPLICATION_NAME="formsflow.ai"
   REACT_APP_WEB_BASE_CUSTOM_URL=""
   REACT_APP_USER_ACCESS_PERMISSIONS="{accessAllowApplications:false,accessAllowSubmissions:false}"

   echo window['"_env_"'] = "{">>config.js
   echo "NODE_ENV":"\""$NODE_ENV"\"",>>config.js
   echo "REACT_APP_API_SERVER_URL":"\""$REACT_APP_API_SERVER_URL"\"",>>config.js
   echo "REACT_APP_API_PROJECT_URL":"\""$REACT_APP_API_PROJECT_URL"\"",>>config.js
   echo "REACT_APP_KEYCLOAK_CLIENT":"\""$REACT_APP_KEYCLOAK_CLIENT"\"",>>config.js
   echo "REACT_APP_KEYCLOAK_URL_REALM":"\""$REACT_APP_KEYCLOAK_URL_REALM"\"",>>config.js
   echo "REACT_APP_KEYCLOAK_URL":"\""$REACT_APP_KEYCLOAK_URL"\"",>>config.js
   echo "REACT_APP_WEB_BASE_URL":"\""$REACT_APP_WEB_BASE_URL"\"",>>config.js
   echo "REACT_APP_BPM_URL":"\""$REACT_APP_BPM_URL"\"",>>config.js
   echo "REACT_APP_WEBSOCKET_ENCRYPT_KEY":"\""$REACT_APP_WEBSOCKET_ENCRYPT_KEY"\"",>>config.js
   echo "REACT_APP_APPLICATION_NAME":"\""$REACT_APP_APPLICATION_NAME"\"",>>config.js
   echo "REACT_APP_WEB_BASE_CUSTOM_URL":"\""$REACT_APP_WEB_BASE_CUSTOM_URL"\"",>>config.js
   echo "REACT_APP_USER_ACCESS_PERMISSIONS":"$REACT_APP_USER_ACCESS_PERMISSIONS"}>>config.js

   cd ../
}

#############################################################
###################### forms-flow-Analytics #################
#############################################################

function formsFlowAnalytics
{
    REDASH_HOST=http://$ipadd:7001
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
    REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS=Content-Type,Authorization
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

function formsFlowBpm
{
    FORMSFLOW_API_URL=http://$ipadd:$webapi_port
    WEBSOCKET_SECURITY_ORIGIN=http://$ipadd:3000
    SESSION_COOKIE_SECURE=false

    echo KEYCLOAK_URL=$KEYCLOAK_URL >> .env
    echo KEYCLOAK_BPM_CLIENT_SECRET=$KEYCLOAK_BPM_CLIENT_SECRET >>.env
    echo FORMSFLOW_API_URL=$FORMSFLOW_API_URL >>.env
    echo WEBSOCKET_SECURITY_ORIGIN=$WEBSOCKET_SECURITY_ORIGIN >> .env
    echo SESSION_COOKIE_SECURE=${SESSION_COOKIE_SECURE} >> .env
    docker-compose -f $docker_compose_file up --build -d forms-flow-bpm
}

#############################################################
######################## forms-flow-webapi ##################
#############################################################

function formsFlowApi
{
    BPM_API_URL=http://$ipadd:8000/camunda
    echo BPM_API_URL=$BPM_API_URL >> .env
    if [[ $ANALYTICS == 1 ]]; then (
        echo What is your Redash API key?
        read INSIGHT_API_KEY
        INSIGHT_API_URL=http://$ipadd:7001
        echo INSIGHT_API_URL=$INSIGHT_API_URL >> .env
        echo INSIGHT_API_KEY=$INSIGHT_API_KEY >> .env
    )
    fi
    
    docker-compose -f $docker_compose_file up --build -d forms-flow-webapi
}

#############################################################
######################## forms-flow-forms ###################
#############################################################

function formsFlowForms
{
    cd ../docker-compose
    FORMIO_DEFAULT_PROJECT_URL=http://$ipadd:3001

    echo FORMIO_DEFAULT_PROJECT_URL=$FORMIO_DEFAULT_PROJECT_URL>>.env

    docker-compose -f $docker_compose_file up --build -d forms-flow-forms

}
function formsFlowWeb
{
cd ../docker-compose/
docker-compose -f $docker_compose_file up --build -d forms-flow-web
isUp
}

#############################################################
########################### Keycloak ########################
#############################################################

function keycloak
{
    cd ../docker-compose/
    if [[ -f .env ]]; then
     rm .env
    fi
    function defaultinstallation
    {
        echo WE ARE SETING UP OUR DEFAULT KEYCLOCK FOR YOU
        printf "%s " "Press enter to continue"
        read that
        echo Please wait, keycloak is setting up!
        docker-compose -f $docker_compose_file up --build -d keycloak
    }
}
function orderwithanalytics
{
  echo installation will be completed in the following order:
  echo 1. keycloak
  echo 2. analytics
  echo 3. forms
  echo 4. camunda
  echo 5. webapi
  echo 6. web
  printf "%s " "Press enter to continue"
  read that
  main
}
function withoutanalytics
{
  echo installation will be completed in the following order:
  echo 1. keycloak
  echo 2. forms
  echo 3. camunda
  echo 4. webapi
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

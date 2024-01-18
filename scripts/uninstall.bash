#!/bin/bash
docker_compose_file='docker-compose.yml'
if [ "$(uname -m)" == "arm64" ]; then
    docker_compose_file='docker-compose-arm64.yml'
fi

echo "Do you want to uninstall formsflow.ai installation? [y/n]" 
read choice
if [[ $choice == "y" ]]; then
    cd ../docker-compose
    docker-compose -p formsflow-ai -f analytics-docker-compose.yml down
    docker-compose -p formsflow-ai -f $docker_compose_file down
    docker images | grep "forms-flow" | awk '{print $3}' | xargs docker image rm
fi

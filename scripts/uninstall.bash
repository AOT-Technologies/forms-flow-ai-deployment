#!/bin/bash
docker_compose_file='docker-compose.yml'
if [ "$(uname -m)" == "arm64" ]; then
    docker_compose_file='docker-compose-arm64.yml'
fi

echo "Do you want to uninstall formsflow.ai installation? [y/n]" 
read choice
if [[ $choice == "y" ]]; then
    cd ../docker-compose
    docker-compose -f analytics-docker-compose.yml down
    docker-compose -f $docker_compose_file down
fi

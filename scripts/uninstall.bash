#!/bin/bash
echo "Do you wish to uninstall Forms Flow and all related volumes and images? [y/n]" 
read choice
if [[ $choice == "y" ]]; then
    UNINSTALL=1
elif [[ $choice == "n" ]]; then
    UNINSTALL=0
fi
#############################################################
######################### main function #####################
#############################################################

function main
{

  if [[ $UNINSTALL == 1 ]]; then
  
     docker compose -f ../docker-compose/analytics-docker-compose.yml down --rmi --volumes
     docker compose -f ../docker-compose/docker-compose.yml down --rmi --volumes
  fi

}


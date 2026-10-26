#!/bin/bash

# ============================================
# formsflow.ai Uninstall Script
# ============================================

echo "*******************************************"
echo "*   formsflow.ai Uninstallation Script   *"
echo "*******************************************"
echo ""

# Detect Docker Compose command
COMPOSE_COMMAND=""
if docker compose version &>/dev/null; then
    COMPOSE_COMMAND="docker compose"
elif docker-compose version &>/dev/null; then
    COMPOSE_COMMAND="docker-compose"
else
    echo "WARNING: Neither 'docker compose' nor 'docker-compose' is installed."
    echo "Docker containers may not be stopped properly."
    echo ""
    read -p "Continue anyway? [y/n] " continue_choice
    if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
fi

if [ -n "$COMPOSE_COMMAND" ]; then
    echo "Using: $COMPOSE_COMMAND"
    echo ""
fi

# ================== Functions ===================

# #############################################################
# ################### Main Function ###########################
# #############################################################

main() {
    forms_flow_all "../docker-compose"
    forms_flow_analytics "../docker-compose"
    remove_keycloak_customizations
    prune_docker
    clear_env "../docker-compose"
    remove_folders "../docker-compose"
    return 0
}

# #############################################################
# ################### forms-flow-all ##########################
# #############################################################

forms_flow_all() {
    if [ -d "$1" ]; then
        if [ -f "$1/docker-compose.yml" ]; then
            echo "Stopping formsflow.ai main containers..."
            if [ -n "$COMPOSE_COMMAND" ]; then
                $COMPOSE_COMMAND -p formsflow-ai -f "$1/docker-compose.yml" down
                echo "✓ Main containers stopped"
            else
                echo "⚠ Skipped: Docker Compose not available"
            fi
        else
            echo "docker-compose.yml not found in $1"
        fi
    else
        echo "Directory $1 not found"
    fi
    echo ""
    return 0
}

# #############################################################
# ################### forms-flow-analytics ####################
# #############################################################

forms_flow_analytics() {
    if [ -d "$1" ]; then
        if [ -f "$1/analytics-docker-compose.yml" ]; then
            echo "Stopping formsflow.ai analytics containers..."
            if [ -n "$COMPOSE_COMMAND" ]; then
                $COMPOSE_COMMAND -p formsflow-ai -f "$1/analytics-docker-compose.yml" down
                echo "✓ Analytics containers stopped"
            else
                echo "⚠ Skipped: Docker Compose not available"
            fi
        else
            echo "analytics-docker-compose.yml not found in $1"
        fi
    else
        echo "Directory $1 not found"
    fi
    echo ""
    return 0
}

# ##############################################################
# ################### Clear Environment File ###################
# ##############################################################

clear_env() {
    if [ -f "$1/.env" ]; then
        echo "Removing environment file..."
        rm -f "$1/.env"
        echo "✓ Environment file removed"
    else
        echo ".env not found in $1"
    fi
    echo ""
    return 0
}

# ##############################################################
# ################### Remove Data Folders ######################
# ##############################################################

remove_folders() {
    local removed_count=0
    
    echo "Removing data folders..."
    
    if [ -d "$1/postgres" ]; then
        rm -rf "$1/postgres"
        echo "✓ postgres folder removed"
        ((removed_count++))
    else
        echo "  postgres folder not found in $1"
    fi

    if [ -d "$1/mongodb" ]; then
        rm -rf "$1/mongodb"
        echo "✓ mongodb folder removed"
        ((removed_count++))
    else
        echo "  mongodb folder not found in $1"
    fi
    
    if [ $removed_count -eq 0 ]; then
        echo "  No data folders to remove"
    fi
    
    echo ""
    return 0
}

# #############################################################
# ########## Remove Keycloak customizations volume ############
# #############################################################

# The keycloak_custom_data volume only holds files copied from the keycloak-customizations
# image (realm import, themes, providers), never user data. Docker fills a named volume only
# when it is first created, so remove it to make the next install use the realm and providers
# of the version and edition being installed.
remove_keycloak_customizations() {
    if docker volume inspect formsflow-ai_keycloak_custom_data &>/dev/null; then
        echo "Removing Keycloak customizations volume..."
        docker volume rm formsflow-ai_keycloak_custom_data >/dev/null 2>&1
        echo "✓ Keycloak customizations volume removed"
        echo ""
    fi
    return 0
}

# #############################################################
# ############# Prune Docker Resources ########################
# #############################################################

prune_docker() {
    echo "Cleaning up Docker resources..."
    
    # Prune volumes
    echo "Removing unused volumes..."
    docker volume prune -f
    
    # Prune images with formsflow label
    echo "Removing formsflow.ai images..."
    docker image prune --all -f --filter label=Name="formsflow"
    
    echo "✓ Docker cleanup complete"
    echo ""
    return 0
}

# #############################################################
# ############# Remove Docker Volumes #########################
# #############################################################

remove_volumes() {
    echo "Checking for formsflow.ai Docker volumes..."
    
    # List volumes that might be related to formsflow.ai
    volumes=$(docker volume ls -q | grep -E "formsflow|keycloak|postgres|mongodb" 2>/dev/null)
    
    if [ -n "$volumes" ]; then
        echo "Found the following volumes:"
        echo "$volumes"
        echo ""
        read -p "Do you want to remove these volumes? [y/n] " remove_vol
        
        if [[ "$remove_vol" =~ ^[Yy]$ ]]; then
            echo "$volumes" | xargs docker volume rm 2>/dev/null
            echo "✓ Volumes removed"
        else
            echo "Volumes kept"
        fi
    else
        echo "No formsflow.ai volumes found"
    fi
    
    echo ""
    return 0
}

# ====================== Start Script ==========================

read -p "Do you want to uninstall formsflow.ai installation? [y/n] " choice
if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo ""
echo "============================================"
echo "Starting uninstallation process..."
echo "============================================"
echo ""

# Optional: Remove Docker volumes
read -p "Do you also want to remove Docker volumes (all data will be lost)? [y/n] " vol_choice
remove_vols=0
if [[ "$vol_choice" =~ ^[Yy]$ ]]; then
    remove_vols=1
fi

echo ""

# Run main uninstallation
main

# Remove volumes if requested
if [ $remove_vols -eq 1 ]; then
    remove_volumes
fi

echo "============================================"
echo "✓ formsflow.ai successfully uninstalled"
echo "============================================"
echo ""

exit 0
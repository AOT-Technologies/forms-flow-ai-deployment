# Formsflow.ai Deployment Using Docker Swarm
This guide will walk you through deploying Formsflow.ai using Docker Swarm.


## Step 1: Initialize Docker Swarm
Run the following command on the manager node to initialize Docker Swarm:

```
docker swarm init
```

## Step 2: Clone the Repository
Clone the forms-flow-ai-deployment repository:

```
git clone https://github.com/AOT-Technologies/forms-flow-ai-deployment.git 
```

## Step 3: Configure the .env File
Make sure your current working directory is forms-flow-ai-deployment/docker-compose/docker-swarm. 

1. Rename the sample.env file to .env.
2. Edit the .env file and update {your-ip-address} with your host system's IP address.

## Step 4: Install Keycloak
Deploy Keycloak using the following command:

```
docker stack deploy -c keycloak-docker-compose.yml formsflow
```

Keycloak should be up and available at http://localhost:8080/auth/.

The default username for Keycloak is **admin**, and the default password is **changeme**

## Step 5: Install Analytics
**Note:** If you need Redash Analytics Engine in the installation,

Deploy Analytics using the following command:

```
docker stack deploy -c analytics-docker-compose.yml formsflow
```
Analytics should be up and available at http://localhost:7001.

The Redash application should be available for use at port defaulted to 7000. Open http://localhost:7001/ on your machine and register with any valid credentials.

## Step 6: Install Formsflow Components

Edit the **docker-compose.yml** file and update {your-ip-address} with your host system's IP address.

**Note:** 
If you require the Redash Analytics Engine in your installation, you'll need to add the INSIGHT_API_KEY to the docker-compose.yml file.

To get the Redash API key, log in to http://localhost:7001/, Choose Settings » Account, and copy the API Key.

In the docker-compose.yml file, find the **environment** section Within this section, find the line that sets **INSIGHT_API_KEY:**

    environment:
      INSIGHT_API_KEY: ${INSIGHT_API_KEY}

Replace **${INSIGHT_API_KEY}** with the API Key you copied.

Deploy Formsflow components using the following command:

```
docker stack deploy -c docker-compose.yml formsflow
```
Check the status of the services:

```
docker service ls
```

## Health Check
1. **Formsflow.ai Web** should be up and available at http://localhost:3000/.
2. **Formio** should be up and available at http://localhost:3001/checkpoint/.
3. **Webapi** should be up and available at http://localhost:5000/.
4. **BPM** should be up and available at http://localhost:8000/camunda/.
5. **Documents-Api** should be up and available at http://localhost:5006/.


## Step 7: Uninstall Formsflow

To uninstall Formsflow, run the following command:

```
docker stack rm formsflow
```
## Forms-flow-ai Installation

In this document, you will see the basic details to install and run the application manually and automatically.

## Table of Contents
- [Forms-flow-ai Installation](#forms-flow-ai-installation)
- [Table of Contents](#table-of-contents)
- [Manual Installation](#manual-installation)
  - [Running the application- "Analytics"](#running-the-application--analytics)
    - [To stop the application](#to-stop-the-application)
- [Quick Installation](#quick-installation)
  - [Health Check](#health-check)

   
## Manual Installation

* Make sure your current working directory is "/forms-flow-ai-deployment/docker-compose".
* Rename the file [sample.env](./sample.env) to **.env** if you are installing manually.
* Edit the config.js file and add the corresponding ip address and set the realm name as "forms-flow-ai" or the realm name of yours.
* Modify the environment variables in the newly created **.env** file if needed. Environment variables are given in the table below,
* **NOTE : `{your-ip-address}` given inside the `.env` file should be changed to your host system IP address. Please take special care to identify the correct IP address if your system has multiple network cards**

* Run `docker-compose up -d keycloak` to start keycloak  
* Run `docker-compose up -d` to start. (PS: Use docker-compose-arm64.yml file for ARM processors. e.g, Apple M1) 
                   
*NOTE: Use --build command with the start command to reflect any future **.env** / code changes eg : `docker-compose up --build -d`*


### Running the application- "Analytics"

* Run `docker-compose -f analytics-docker-compose.yml run --rm server create_db` to setup database and to create tables.
* Run `docker-compose -f analytics-docker-compose.yml up --build -d` to start analytics.
   
*NOTE: Use --build command with the start command to reflect any future **.env** / code changes eg : `docker-compose up --build -d`*

#### To stop the application

* Run `docker-compose stop` to stop.


## Quick Installation

* Make sure your current working directory is "/forms-flow-ai-deployment/scripts".
* Now just run install.bat/bash according to your operating system.
  
### Health Check
* Analytics should be up and available for use at port defaulted to 7001 i.e. http://localhost:7001/
* Business Process Engine should be up and available for use at port defaulted to 8000 i.e. http://localhost:8000/camunda/
* FormIO should be up and available for use at port defaulted to 3001 i.e. http://localhost:3001/
* formsflow.ai Rest API should be up and available for use at port defaulted to 5000 i.e. http://localhost:5000/checkpoint
* formsflow.ai web application should be up and available for use at port defaulted to 3000 i.e. http://localhost:3000/



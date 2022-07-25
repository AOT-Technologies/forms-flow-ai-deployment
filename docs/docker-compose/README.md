## Forms-flow-ai Installation

In this document, you will see the basic details to install and run the application manually and automatically.

## Table of Contents
1. [Manual Installation](#Manual-Installation)
   * [Health Check](#health-check)
   * [Running the application](#Running-the-application)
   * [Stop the application](#To-stop-the-application)
2. [Quick Installation](#Quick-Installtion)
3. [Health Check](#health-check)

   
## Manual Installation

* Make sure your current working directory is "/forms-flow-ai-deployment/docker-compose".
* Rename the file [sample.env](./sample.env) to **.env** if you are installing manually.
* Modify the environment variables in the newly created **.env** file if needed. Environment variables are given in the table below,
* **NOTE : `{your-ip-address}` given inside the `.env` file should be changed to your host system IP address. Please take special care to identify the correct IP address if your system has multiple network cards**

* Run `docker-compose -f docker-compose-local.yml up -d keycloak` to start keycloak
* Follow the below steps for mapping the role IDs.   
   - Start the forms-flow-forms service. 
       - Run `docker-compose -f docker-compose-local.yml up -d forms-flow-forms` to start. 
       
#### Health Check

   - Access forms-flow-forms at port defaulted to 3001 i.e. http://localhost:3001/ .
   
           Default Login Credentials
           -----------------
           User Name / Email : admin@example.com
           Password  : changeme   
                   
*NOTE: Use --build command with the start command to reflect any future **.env** / code changes eg : `docker-compose -f docker-compose-local.yml up --build -d`*


### Running the application

* Run `docker-compose -f docker-compose-local.yml up -d` to start.
* Run `docker-compose -f analytics-docker-compose.yml up --build -d` to start analytics.
   
*NOTE: Use --build command with the start command to reflect any future **.env** / code changes eg : `docker-compose -f docker-compose-local.yml up --build -d`*

#### To stop the application

* Run `docker-compose stop` to stop.


## Quick Installation

* Make sure your current working directory is "/forms-flow-ai-deployment/scripts".
* Now just run install.bat/bash according to your operating system.
  
### Health Check
* Analytics should be up and available for use at port defaulted to 7000 i.e. http://localhost:7000/
* Business Process Engine should be up and available for use at port defaulted to 8000 i.e. http://localhost:8000/camunda/
* FormIO should be up and available for use at port defaulted to 3001 i.e. http://localhost:3001/
* formsflow.ai Rest API should be up and available for use at port defaulted to 5000 i.e. http://localhost:5000/checkpoint
* formsflow.ai web application should be up and available for use at port defaulted to 3000 i.e. http://localhost:3000/



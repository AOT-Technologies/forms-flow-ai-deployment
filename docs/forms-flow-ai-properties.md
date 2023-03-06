This page elaborates all the properies that is required for the installation.

NOTE: The variable name given inside docker-compose is the one that we use in our .env file and the one in docker  is used in openshift environment.

Variable name (Docker-compose) | Variable name (Docker) | Descreption | Default value |
--- | --- | --- | --- 
`KEYCLOAK_JDBC_DB`|`DB_DATABASE`|keycloak database name used on installation to create the database|`keycloak`
`KEYCLOAK_JDBC_USER`|`DB_USER `|keycloak database postgres user used on installation to create the database|`postgres`
`KEYCLOAK_JDBC_PASSWORD`|`DB_PASSWORD `|keycloak database postgres password used on installation to create the database|`changeit`
`KEYCLOAK_ADMIN_USER`|`KEYCLOAK_USER `|keycloak admin user name|`admin`
`KEYCLOAK_ADMIN_PASSWORD`|`KEYCLOAK_PASSWORD `|keycloak admin password|`changeme`
`KEYCLOAK_URL`:triangular_flag_on_post:| |URL to your Keycloak server|`http://{your-ip-address}:8080`
`KEYCLOAK_URL_REALM`| |The Keycloak realm to use|`forms-flow-ai`
`KEYCLOAK_BPM_CLIENT_ID`|`KEYCLOAK_CLIENTID `|Your Keycloak Client ID within the realm|`forms-flow-bpm`
`CAMUNDA_JDBC_URL`| |Postgres JDBC DB Connection URL used on installation to create the database|`jdbc:postgresql://forms-flow-bpm-db:5432/formsflow-bpm`
`CAMUNDA_JDBC_DRIVER`| |Postgres JDBC Database Driver|`org.postgresql.Driver`
`CAMUNDA_POSTGRES_USER`| |Postgres Database Username used on installation to create the database|`admin`
`CAMUNDA_POSTGRES_PASSWORD`| |Postgres Database Password used on installation to create the database|`changeme`
`CAMUNDA_JDBC_DB_NAME`| |Postgres Database Name used on installation to create the database|`formsflow-bpm`
`FORMSFLOW_API_URL`:triangular_flag_on_post:|`REACT_APP_WEB_BASE_URL`|formsflow.ai Rest API URI|`http://{your-ip-address}:5000`
`FORMIO_DEFAULT_PROJECT_URL`:triangular_flag_on_post:|` FORMIO_URL`|The URL of the forms-flow-forms server|`http://{your-ip-address}:3001`
`FORMIO_ROOT_EMAIL`|`ROOT_EMAIL `|forms-flow-forms admin login|`admin@example.com`
`FORMIO_ROOT_PASSWORD`|`ROOT_PASSWORD `|forms-flow-forms admin password|`changeme`
`WEBSOCKET_SECURITY_ORIGIN` :triangular_flag_on_post:| |Camunda task event streaming, for multiple origins you can separate them using a comma| `http://{your-ip-address}:3000`
`WEBSOCKET_MESSAGE_TYPE`| |Camunda task event streaming. Message type|`TASK_EVENT`
`WEBSOCKET_ENCRYPT_KEY`|`REACT_APP_WEBSOCKET_ENCRYPT_KEY `|Camunda task event streaming. AES encryption of token|`giert989jkwrgb@DR55`
`MULTI_TENANCY_ENABLED`|`enableMultiTenancy `|Multi tenancy enabled flag for the environment|`true/false`
`FORMSFLOW_ADMIN_URL`|` formsFlowinUrAdml`|Only needed if multi tenancy is enabled|`http://{your-ip-address}:5001/`
`DATA_ANALYSIS_URL`| |sentiment analysis url|`http://{your-ip-address}:6000/analysis`
`APP_SECURITY_ORIGIN`| |CORS setup, for multiple origins you can separate them using a comma| `*`
`CAMUNDA_APP_ROOT_LOG_FLAG`| |Log level setting|`error`
`DATA_BUFFER_SIZE`|` maxInMemorySize`|Configure a limit on the number of bytes that can be buffered for webclient|`2  (In MB)`
`IDENTITY_PROVIDER_MAX_RESULT_SIZE`|` maxResultSize`|Maximum result size for Keycloak user queries|`250`
`BPM_CLIENT_CONN_TIMEOUT`|`connectionTimeout `|Webclient Connection timeout in milli seconds|`5000`
`INSIGHT_API_URL`:triangular_flag_on_post: | | The forms-flow-analytics Api base end-point| <http://{your-ip-address}:7001>
`INSIGHT_API_KEY` :triangular_flag_on_post: | | The forms-flow-analytics admin API key| `Get the api key from forms-flow-analytics (REDASH) by following the 'Get the Redash API Key' steps from [here](../forms-flow-analytics/README.md#get-the-redash-api-key)`
`FORMSFLOW_API_DB_USER`|` POSTGRES_USER`|formsflow database postgres user used on installation to create the database|`postgres`
`FORMSFLOW_API_DB_PASSWORD`|`POSTGRES_PASSWORD `|formsflow database postgres password used on installation to create the database|`changeme`
`FORMSFLOW_API_DB_NAME`|`POSTGRES_DB `|formsflow database name used on installation to create the database|`FORMSFLOW_API_DB`
`FORMSFLOW_API_DB_URL`|`DATABASE_URL `|JDBC DB Connection URL for formsflow|`postgresql://postgres:changeme@forms-flow-webapi-db:5432/webapi`
`KEYCLOAK_BPM_CLIENT_SECRET`|`KEYCLOAK_CLIENTSECRET `|Client Secret of Camunda client in realm|`e4bdbd25-1467-4f7f-b993-bc4b1944c943` <br><br>`To generate a new keycloak client seceret by yourself follow the steps from` [here](../forms-flow-idm/keycloak/README.md#getting-the-client-secret)
`KEYCLOAK_WEB_CLIENT_ID`|` REACT_APP_KEYCLOAK_CLIENT`|Client ID for formsflow to register with Keycloak|`forms-flow-web`
`CAMUNDA_API_URL`:triangular_flag_on_post:|`REACT_APP_CAMUNDA_API_URI `|Camunda Rest API URL|`http://{your-ip-address}:8000/camunda`
`FORMSFLOW_API_CORS_ORIGINS`| |formsflow.ai Rest API allowed origins, for allowing multiple origins you can separate host address using a comma seperated string or use * to allow all origins| `*`
`FORMIO_DB_USERNAME`|`MONGO_INITDB_ROOT_USERNAME `|Mongo Root Username. Used on installation to create the database.Choose your own|`admin`
`FORMIO_DB_PASSWORD`|` MONGO_INITDB_ROOT_PASSWORD`|Mongo Root Password|`changeme`
`FORMIO_DB_NAME`|`MONGO_INITDB_DATABASE `|Mongo Database  Name used on installation to create the database.Choose your own|`formio`
`FORMIO_JWT_SECRET`|`REACT_APP_FORMIO_JWT_SECRET `|forms-flow-forms jwt secret|`--- change me now ---`
`NODE_ENV`| |Define project level configuration|`development`
`KEYCLOAK_WEB_CLIENTID`| |Your Keycloak Client ID within the realm| `forms-flow-web`
`APPLICATION_NAME`|`REACT_APP_APPLICATION_NAME `|Application name is used to provide clients application name||
`WEB_BASE_CUSTOM_URL`|`REACT_APP_WEB_BASE_CUSTOM_URL `|Clients can use WEB_BASE_CUSTOM_URL env variable to provide their custom URL||
`USER_ACCESS_PERMISSIONS`|` REACT_APP_USER_ACCESS_PERMISSIONS`|JSON formatted permissions to enable / disable few access on user login.| `{"accessAllowApplications":false,"accessAllowSubmissions":false}`
`CLIENT_ROLE`|` REACT_APP_CLIENT_ROLE`|The role name used for client users| `formsflow-client`
`CLIENT_ROLE_ID`:triangular_flag_on_post:|`REACT_APP_CLIENT_ID `|forms-flow-forms client role Id|`must get the client role Id value from Prerequisites step 1 above.`)
`REVIEWER_ROLE`|`REACT_APP_STAFF_REVIEWER_ROLE `|The role name used for reviewer users|`formsflow-reviewer`
`REVIEWER_ROLE_ID`:triangular_flag_on_post:|`REACT_APP_STAFF_REVIEWER_ID `|forms-flow-forms reviewer role Id|`must get the reviewer role Id value from Prerequisites step 1 above..`
`DESIGNER_ROLE`|`REACT_APP_STAFF_DESIGNER_ROLE `|The role name used for designer users|`formsflow-designer`
`DESIGNER_ROLE_ID`:triangular_flag_on_post:|` REACT_APP_STAFF_DESIGNER_ID`|forms-flow-forms administrator role Id|`must get the administrator role Id value from Prerequisites step 1 above..`
`ANONYMOUS_ID`|`REACT_APP_ANONYMOUS_ID `|forms-flow-forms anonymous role Id|`must get the anonymous role Id value from Prerequisites step 1 above..`
`USER_RESOURCE_ID`:triangular_flag_on_post:|`  REACT_APP_USER_RESOURCE_FORM_ID`|User forms form-Id|`must get the value from the step 1 above..`
@echo off

set /p choice=Do you want analytics to include in the installation? [y/n]
if %choice%==y (
    set /a analytics=1
) else (
    set /a analytics=0
)

call:find-my-ip
call:main %analytics% %keycloak%

echo ********************** formsflow.ai is successfully installed ****************************
pause

EXIT /B %ERRORLEVEL%


:: ================&&&&&&===  Functions  ====&&&&&&&&&============================

:: #############################################################
:: ################### Main Function ###########################
:: #############################################################

:main
    call:set-common-properties
    call:keycloak ..\docker-compose %~2 
    if %~1==1 (
        call:forms-flow-analytics ..\docker-compose
    )
    call:forms-flow-forms ..\docker-compose
    call:forms-flow-bpm ..\docker-compose
    call:forms-flow-web ..\docker-compose
    call:forms-flow-api ..\docker-compose %~1
    call:forms-flow-documents ..\docker-compose
    call:forms-flow-data-analysis-api ..\docker-compose
    call:isUp
    EXIT /B 0
	

:: #############################################################
:: ##################### Check working ########################
:: #############################################################    

:isUp
   :Check if the web API is up
     for /f %%a in ('curl -LI "http://%ip-add%:5001" -o nul -w "%%{http_code}" -s') do set "HTTP=%%a"
     if "%HTTP%" == "200" (
       echo formsflow.ai is successfully installed.
       EXIT /B 0
     ) else (
       echo Finishing setup.
       ping 127.0.0.1 -n 6 >nul
       goto isUp
     )

:: #############################################################
:: ################### Finding IP Address ######################
:: #############################################################

:find-my-ip
    FOR /F "tokens=4 delims= " %%i in ('route print ^| find " 0.0.0.0"') do set ip-add=%%i
    set /p choice=Confirm that your IPv4 address is %ip-add%? [y/n]
    if %choice%==y (
           EXIT /B 0
     ) else (
       set /p ip-add="What is your IPv4 address?"
     )
    EXIT /B 0
  
:set-common-properties
    set WEBSOCKET_ENCRYPT_KEY=giert989jkwrgb@DR55
    set KEYCLOAK_BPM_CLIENT_SECRET=e4bdbd25-1467-4f7f-b993-bc4b1944c943
    EXIT /B 0

:: #############################################################
:: ########################### Keycloak ########################
:: #############################################################

:keycloak

        if exist %~1\.env (
        del %~1\.env
        )
	    docker-compose -p formsflow-ai -f %~1\docker-compose.yml up --build -d keycloak
		timeout 5
		set KEYCLOAK_URL=http://%ip-add%:8080
	)
 	EXIT /B 0
   
:: #############################################################
:: ################### forms-flow-forms ########################
:: #############################################################

:forms-flow-forms

    set FORMIO_DEFAULT_PROJECT_URL=http://%ip-add%:3001
    echo FORMIO_DEFAULT_PROJECT_URL=%FORMIO_DEFAULT_PROJECT_URL%>>%~1\.env
    docker-compose -p formsflow-ai -f %~1\docker-compose.yml up --build -d forms-flow-forms
    timeout 5
    EXIT /B 0
	
:: #########################################################################
:: ######################### forms-flow-web ################################
:: #########################################################################

:forms-flow-web

    SETLOCAL
    set BPM_API_URL=http://%ip-add%:8000/camunda
    echo BPM_API_URL=%BPM_API_URL%>>%~1\.env

    docker-compose -p formsflow-ai -f %~1\docker-compose.yml up --build -d forms-flow-web
    EXIT /B 0

:: #############################################################
:: ################### forms-flow-bpm ########################
:: #############################################################

:forms-flow-bpm

    SETLOCAL
    set FORMSFLOW_API_URL=http://%ip-add%:5001
    set WEBSOCKET_SECURITY_ORIGIN=http://%ip-add%:3000
    set SESSION_COOKIE_SECURE=false

    echo KEYCLOAK_URL=%KEYCLOAK_URL%>>%~1\.env
    echo KEYCLOAK_BPM_CLIENT_SECRET=%KEYCLOAK_BPM_CLIENT_SECRET%>>%~1\.env
    echo FORMSFLOW_API_URL=%FORMSFLOW_API_URL%>>%~1\.env
    echo WEBSOCKET_SECURITY_ORIGIN=%WEBSOCKET_SECURITY_ORIGIN%>>%~1\.env
    echo SESSION_COOKIE_SECURE=%SESSION_COOKIE_SECURE%>>%~1\.env
    ENDLOCAL
    docker-compose -p formsflow-ai -f %~1\docker-compose.yml up --build -d forms-flow-bpm
    timeout 6
    EXIT /B 0  

:: #############################################################
:: ################### forms-flow-analytics ########################
:: #############################################################

:forms-flow-analytics

    SETLOCAL
    set REDASH_HOST=http://%ip-add%:7001
    set PYTHONUNBUFFERED=0
    set REDASH_LOG_LEVEL=INFO
    set REDASH_REDIS_URL=redis://redis:6379/0
    set POSTGRES_USER=postgres
    set POSTGRES_PASSWORD=changeme
    set POSTGRES_DB=postgres
    set REDASH_COOKIE_SECRET=redash-selfhosted
    set REDASH_SECRET_KEY=redash-selfhosted
    set REDASH_DATABASE_URL=postgresql://postgres:changeme@postgres/postgres
    set REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN=*
    set REDASH_REFERRER_POLICY=no-referrer-when-downgrade
    set REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS=Content-Type, Authorization
    echo REDASH_HOST=%REDASH_HOST%>>%~1\.env
    echo PYTHONUNBUFFERED=%PYTHONUNBUFFERED%>>%~1\.env
    echo REDASH_LOG_LEVEL=%REDASH_LOG_LEVEL%>>%~1\.env
    echo REDASH_REDIS_URL=%REDASH_REDIS_URL%>>%~1\.env
    echo POSTGRES_USER=%POSTGRES_USER%>>%~1\.env
    echo POSTGRES_PASSWORD=%POSTGRES_PASSWORD%>>%~1\.env
    echo POSTGRES_DB=%POSTGRES_DB%>>%~1\.env
    echo REDASH_COOKIE_SECRET=%REDASH_COOKIE_SECRET%>>%~1\.env
    echo REDASH_SECRET_KEY=%REDASH_SECRET_KEY%>>%~1\.env
    echo REDASH_DATABASE_URL=%REDASH_DATABASE_URL%>>%~1\.env
    echo REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN=%REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN%>>%~1\.env
    echo REDASH_REFERRER_POLICY=%REDASH_REFERRER_POLICY%>>%~1\.env
    echo REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS=%REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS%>>%~1\.env
    ENDLOCAL
    docker-compose -p formsflow-ai -f %~1\analytics-docker-compose.yml run --rm server create_db
    docker-compose -p formsflow-ai -f %~1\analytics-docker-compose.yml up --build -d
	timeout 5
    EXIT /B 0

:: #############################################################
:: ################### forms-flow-api ########################
:: #############################################################

:forms-flow-api

    SETLOCAL

    set BPM_API_URL=http://%ip-add%:8000/camunda
    if %~2==1 (
        set /p INSIGHT_API_KEY="What is your Redash API key?"
        set INSIGHT_API_URL=http://%ip-add%:7001
    )
    echo BPM_API_URL=%BPM_API_URL%>>%~1\.env
    if %~2==1 (
        echo INSIGHT_API_URL=%INSIGHT_API_URL%>>%~1\.env
        echo INSIGHT_API_KEY=%INSIGHT_API_KEY%>>%~1\.env
    )
    
    ENDLOCAL
    docker-compose -p formsflow-ai -f %~1\docker-compose.yml up --build -d forms-flow-webapi

:: #############################################################
:: ############### forms-flow-documents-api ####################
:: #############################################################

:forms-flow-documents

  SETLOCAL
  set DOCUMENT_SERVICE_URL=http://%ip-add%:5006
  echo DOCUMENT_SERVICE_URL=%DOCUMENT_SERVICE_URL%>>%~1\.env

  docker-compose -p formsflow-ai -f %~1\docker-compose.yml up --build -d forms-flow-documents-api
    timeout 5
    EXIT /B 0

:forms-flow-data-analysis-api

  SETLOCAL
  set DATA_ANALYSIS_API_BASE_URL=http://%ip-add%:6001
  set DATA_ANALYSIS_DB_URL=postgresql://general:changeme@forms-flow-data-analysis-db:5432/dataanalysis
  echo DATA_ANALYSIS_API_BASE_URL=%DATA_ANALYSIS_API_BASE_URL%>>%~1\.env
  echo DATA_ANALYSIS_DB_URL=%DATA_ANALYSIS_DB_URL%>>%~1\.env

  docker-compose -p formsflow-ai -f %~1\docker-compose.yml up --build -d forms-flow-data-analysis-api
    timeout 5
    EXIT /B 0


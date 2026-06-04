@echo off
setlocal EnableDelayedExpansion

echo *******************************************
echo *     formsflow.ai Installation Script    *
echo *******************************************
echo.

REM Detect the appropriate Docker Compose command
set "COMPOSE_COMMAND="
for /f "tokens=*" %%A in ('docker compose version 2^>nul') do (
    set "COMPOSE_COMMAND=docker compose"
)

if "!COMPOSE_COMMAND!"=="" (
    for /f "tokens=*" %%A in ('docker-compose version 2^>nul') do (
        set "COMPOSE_COMMAND=docker-compose"
    )
)

if "!COMPOSE_COMMAND!"=="" (
    echo ERROR: Neither docker compose nor docker-compose is installed.
    echo Please install Docker Desktop or Docker Engine with Compose.
    pause
    exit /b 1
)

echo Using !COMPOSE_COMMAND!

REM Get Docker version
for /f "tokens=*" %%A in ('docker -v 2^>^&1') do (
    set "docker_info=%%A"
)

set "docker_version="
for /f "tokens=3 delims= " %%A in ("!docker_info!") do (
    set "docker_version=%%A"
    set "docker_version=!docker_version:,=!"
)

echo Docker version: !docker_version!

:: Set the URL where tested versions are uploaded
set "url=https://forms-flow-docker-versions.s3.ca-central-1.amazonaws.com/docker_versions.html"

REM Temporary file for downloaded content
set "versionsFile=tested_versions.tmp"

REM Try to fetch the tested versions using curl with verbose output for debugging
echo Fetching tested Docker versions from !url!...
curl -s -v "%url%" > "%versionsFile%" 2>curl_debug.log

REM Check if the download was successful
if not exist "%versionsFile%" (
    echo Failed to fetch tested versions. Using local version check instead.
    goto :SkipVersionCheck
)

REM Check file size - if zero or very small, download likely failed
for %%A in ("%versionsFile%") do set "fileSize=%%~zA"
if !fileSize! LSS 10 (
    echo Downloaded file is too small or empty. Using local version check instead.
    goto :SkipVersionCheck
)

REM Parse the HTML file to extract version numbers
echo Checking if your Docker version is tested...
set "versionFound="

REM Just search for your version in the file - handle simple HTML or plain text list
findstr /C:"%docker_version%" "%versionsFile%" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set "versionFound=true"
    echo Your Docker version %docker_version% is in the tested versions list.
    goto :SkipVersionCheck
)

REM Try to extract versions from HTML content if simple match failed
for /f "tokens=*" %%B in ('type "%versionsFile%" ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
    for /f "tokens=1 delims=<>" %%C in ("%%B") do (
        if "!docker_version!" equ "%%C" (
            set "versionFound=true"
            echo Your Docker version %docker_version% is in the tested versions list.
            goto :SkipVersionCheck
        )
    )
)

REM If we get here, version was not found in the downloaded list
echo Your Docker version %docker_version% was not found in the tested versions list.
goto :AskToContinue

:AskToContinue
REM If the version was not found, ask the user if they want to continue
if not defined versionFound (
    echo WARNING: This Docker version is not in our tested versions list! 
    set /p continue=Do you want to continue anyway? [y/n] 
    if /i "!continue!" equ "y" (
       echo Continuing with installation...
       goto :SkipVersionCheck
    ) else (
       echo Installation cancelled by user.
       del "%versionsFile%" 2>nul
       del "curl_debug.log" 2>nul
       exit /b 1
    )
)

:SkipVersionCheck
REM Find IP address
echo Finding your IP address...

REM Method 1: Use ipconfig to find IP
set "ip_add="
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r "IPv4.*[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
    set "temp_ip=%%a"
    set "temp_ip=!temp_ip:~1!"
    if not "!temp_ip:127.0.0.=!"=="!temp_ip!" (
        REM Skip localhost addresses
    ) else if "!ip_add!"=="" (
        set "ip_add=!temp_ip!"
    )
)

REM Method 2: Use route as fallback
if "!ip_add!"=="" (
    for /f "tokens=4 delims= " %%i in ('route print ^| find " 0.0.0.0"') do set "ip_add=%%i"
)

if "!ip_add!"=="" (
    echo WARNING: Could not automatically detect your IP address.
    set /p "ip_add=Please enter your IP address manually: "
) else (
    echo Detected IP address: !ip_add!
    set /p "choice=Is this your correct IPv4 address? [y/n] "
    if /i "!choice!" neq "y" (
        set /p "ip_add=Please enter your correct IP address: "
    )
)

echo IP address set to: !ip_add!

REM Clean up temporary file if it exists
if exist "tested_versions.txt" del "tested_versions.txt" 
if exist "tested_versions.tmp" del "tested_versions.tmp" 
if exist "curl_debug.log" del "curl_debug.log" 

REM Find docker-compose files
echo Locating docker-compose files...

set "DOCKER_COMPOSE_DIR="
set "COMPOSE_FILE="
set "ANALYTICS_COMPOSE_FILE="

REM Check current directory
if exist "docker-compose.yml" (
    set "COMPOSE_FILE=docker-compose.yml"
    set "DOCKER_COMPOSE_DIR=."
    echo Found docker-compose.yml in current directory.
)

REM Check parent directory
if not defined COMPOSE_FILE (
    if exist "..\docker-compose.yml" (
        set "COMPOSE_FILE=..\docker-compose.yml"
        set "DOCKER_COMPOSE_DIR=.."
        echo Found docker-compose.yml in parent directory.
    )
)

REM Check docker-compose subdirectory
if not defined COMPOSE_FILE (
    if exist "docker-compose\docker-compose.yml" (
        set "COMPOSE_FILE=docker-compose\docker-compose.yml"
        set "DOCKER_COMPOSE_DIR=docker-compose"
        echo Found docker-compose.yml in docker-compose subdirectory.
    )
)

REM Check parent's docker-compose subdirectory
if not defined COMPOSE_FILE (
    if exist "..\docker-compose\docker-compose.yml" (
        set "COMPOSE_FILE=..\docker-compose\docker-compose.yml"
        set "DOCKER_COMPOSE_DIR=..\docker-compose"
        echo Found docker-compose.yml in parent's docker-compose subdirectory.
    )
)

REM Check for analytics compose file
if defined DOCKER_COMPOSE_DIR (
    if exist "!DOCKER_COMPOSE_DIR!\analytics-docker-compose.yml" (
        set "ANALYTICS_COMPOSE_FILE=!DOCKER_COMPOSE_DIR!\analytics-docker-compose.yml"
        echo Found analytics-docker-compose.yml.
    )
)

if not defined COMPOSE_FILE (
    echo ERROR: Could not find docker-compose.yml file.
    echo Please make sure the file exists in one of these locations:
    echo - Current directory
    echo - Parent directory
    echo - docker-compose subdirectory
    echo - Parent's docker-compose subdirectory
    
    set /p "customPath=Enter the path to docker-compose.yml or press Enter to exit: "
    if "!customPath!"=="" (
        echo Installation cancelled.
        pause
        exit /b 1
    )
    
    if exist "!customPath!" (
        set "COMPOSE_FILE=!customPath!"
        for %%F in ("!COMPOSE_FILE!") do set "DOCKER_COMPOSE_DIR=%%~dpF"
        set "DOCKER_COMPOSE_DIR=!DOCKER_COMPOSE_DIR:~0,-1!"
        echo Using provided docker-compose.yml at !COMPOSE_FILE!
    ) else (
        echo The specified file does not exist.
        echo Installation cancelled.
        pause
        exit /b 1
    )
)

REM Create installation directory if it doesn't exist
if not exist "!DOCKER_COMPOSE_DIR!" (
    echo Creating docker-compose directory...
    mkdir "!DOCKER_COMPOSE_DIR!" 2>nul
)

REM Check for existing installation
if exist "!DOCKER_COMPOSE_DIR!\.env" (
    echo WARNING: Existing installation detected.
    set /p "overwrite=Do you want to overwrite the existing installation? [y/n] "
    if /i "!overwrite!" neq "y" (
        echo Installation cancelled.
        pause
        exit /b 0
    )
    echo Clearing existing environment file...
    del "!DOCKER_COMPOSE_DIR!\.env" 2>nul
)

REM Analytics selection
set /p "choice=Do you want to include analytics in the installation? [y/n] "
if /i "!choice!"=="y" (
    set "analytics=1"
    echo Analytics will be included in the installation.
    
    if not defined ANALYTICS_COMPOSE_FILE (
        echo WARNING: analytics-docker-compose.yml not found in the same directory as docker-compose.yml.
        set /p "continueWithoutAnalytics=Continue without analytics? [y/n] "
        if /i "!continueWithoutAnalytics!" neq "y" (
            echo Installation cancelled.
            pause
            exit /b 0
        )
        set "analytics=0"
        echo Analytics will NOT be included.
    )
) else (
    set "analytics=0"
    echo Analytics will not be included.
)


echo Installation summary:
echo - IP Address: !ip_add!
echo - Analytics: !analytics!
echo - Docker Compose File: !COMPOSE_FILE!
if !analytics!==1 (
    echo - Analytics Compose File: !ANALYTICS_COMPOSE_FILE!
)
echo.
set /p "confirmInstall=Begin installation with these settings? [y/n] "
if /i "!confirmInstall!" neq "y" (
    echo Installation cancelled by user.
    pause
    exit /b 0
)

REM Create new .env file
echo Creating environment configuration...
echo # formsflow.ai Environment Configuration > "!DOCKER_COMPOSE_DIR!\.env"
echo # Generated on %date% at %time% >> "!DOCKER_COMPOSE_DIR!\.env"
echo. >> "!DOCKER_COMPOSE_DIR!\.env"

REM Set common properties
echo Setting common properties...
set "WEBSOCKET_ENCRYPT_KEY=giert989jkwrgb@DR55"
set "KEYCLOAK_BPM_CLIENT_SECRET=e4bdbd25-1467-4f7f-b993-bc4b1944c943"

REM Setup Keycloak
echo Setting up Keycloak...
echo Starting Keycloak container...
!COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up --build -d keycloak
if !ERRORLEVEL! neq 0 (
    echo ERROR: Failed to start Keycloak
    pause
    exit /b !ERRORLEVEL!
)
echo Waiting for Keycloak to initialize...
echo KEYCLOAK_URL=http://!ip_add!:8080 >> "!DOCKER_COMPOSE_DIR!\.env"
echo KEYCLOAK_BPM_CLIENT_SECRET=!KEYCLOAK_BPM_CLIENT_SECRET! >> "!DOCKER_COMPOSE_DIR!\.env"
echo KEYCLOAK_URL_HTTP_RELATIVE_PATH=/auth >> "!DOCKER_COMPOSE_DIR!\.env"
echo KEYCLOAK_WEB_CLIENTID=forms-flow-web >> "!DOCKER_COMPOSE_DIR!\.env"
echo WEBSOCKET_ENCRYPT_KEY=!WEBSOCKET_ENCRYPT_KEY! >> "!DOCKER_COMPOSE_DIR!\.env"

timeout /t 10 /nobreak >nul

REM Setup forms-flow-forms
echo Setting up forms-flow-forms...
echo FORMIO_DEFAULT_PROJECT_URL=http://!ip_add!:3001 >> "!DOCKER_COMPOSE_DIR!\.env"
echo Starting forms-flow-forms container...
!COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up --build -d forms-flow-forms
if !ERRORLEVEL! neq 0 (
    echo ERROR: Failed to start forms-flow-forms
    pause
    exit /b !ERRORLEVEL!
)
echo Waiting for forms-flow-forms to initialize...
timeout /t 10 /nobreak >nul

REM Setup Analytics if selected
if !analytics!==1 (
    echo Setting up forms-flow-analytics...
    echo REDASH_HOST=http://!ip_add!:7001 >> "!DOCKER_COMPOSE_DIR!\.env"
    echo PYTHONUNBUFFERED=0 >> "!DOCKER_COMPOSE_DIR!\.env"
    echo REDASH_LOG_LEVEL=INFO >> "!DOCKER_COMPOSE_DIR!\.env"
    echo REDASH_REDIS_URL=redis://redis:6379/0 >> "!DOCKER_COMPOSE_DIR!\.env"
    echo POSTGRES_USER=postgres >> "!DOCKER_COMPOSE_DIR!\.env"
    echo POSTGRES_PASSWORD=changeme >> "!DOCKER_COMPOSE_DIR!\.env"
    echo POSTGRES_DB=postgres >> "!DOCKER_COMPOSE_DIR!\.env"
    echo REDASH_COOKIE_SECRET=redash-selfhosted >> "!DOCKER_COMPOSE_DIR!\.env"
    echo REDASH_SECRET_KEY=redash-selfhosted >> "!DOCKER_COMPOSE_DIR!\.env"
    echo REDASH_DATABASE_URL=postgresql://postgres:changeme@postgres/postgres >> "!DOCKER_COMPOSE_DIR!\.env"
    echo REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN=* >> "!DOCKER_COMPOSE_DIR!\.env"
    echo REDASH_REFERRER_POLICY=no-referrer-when-downgrade >> "!DOCKER_COMPOSE_DIR!\.env"
    echo REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS=Content-Type, Authorization >> "!DOCKER_COMPOSE_DIR!\.env"
    
    echo Creating analytics database...
    !COMPOSE_COMMAND! -p formsflow-ai -f "!ANALYTICS_COMPOSE_FILE!" run --rm server create_db
    if !ERRORLEVEL! neq 0 (
        echo ERROR: Failed to create analytics database
        pause
        exit /b !ERRORLEVEL!
    )
    echo Starting analytics containers...
    !COMPOSE_COMMAND! -p formsflow-ai -f "!ANALYTICS_COMPOSE_FILE!" up --build -d
    if !ERRORLEVEL! neq 0 (
        echo ERROR: Failed to start analytics containers
        pause
        exit /b !ERRORLEVEL!
    )
    echo Waiting for analytics to initialize...
    timeout /t 10 /nobreak >nul
    
    echo INSIGHT_API_URL=http://!ip_add!:7001 >> "!DOCKER_COMPOSE_DIR!\.env"
    set /p "INSIGHT_API_KEY=Enter your Redash API key: "
    echo INSIGHT_API_KEY=!INSIGHT_API_KEY! >> "!DOCKER_COMPOSE_DIR!\.env"
)

REM Setup BPM
echo Setting up forms-flow-bpm...
echo FORMSFLOW_API_URL=http://!ip_add!:5001 >> "!DOCKER_COMPOSE_DIR!\.env"
echo WEBSOCKET_SECURITY_ORIGIN=http://!ip_add!:3000 >> "!DOCKER_COMPOSE_DIR!\.env"
echo SESSION_COOKIE_SECURE=false >> "!DOCKER_COMPOSE_DIR!\.env"
echo REDIS_URL=redis://!ip_add!:6379/0 >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMSFLOW_DOC_API_URL=http://!ip_add!:5006 >> "!DOCKER_COMPOSE_DIR!\.env"
echo BPM_API_URL=http://!ip_add!:8000/camunda >> "!DOCKER_COMPOSE_DIR!\.env"
echo USER_NAME_DISPLAY_CLAIM=preferred_username >> "!DOCKER_COMPOSE_DIR!\.env"

echo Starting forms-flow-bpm container...
!COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up --build -d forms-flow-bpm
if !ERRORLEVEL! neq 0 (
    echo ERROR: Failed to start forms-flow-bpm
    pause
    exit /b !ERRORLEVEL!
)
echo Waiting for forms-flow-bpm to initialize...
timeout /t 15 /nobreak >nul

REM Setup API
echo Setting up forms-flow-api...
echo WEB_BASE_URL=http://!ip_add!:3000 >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMSFLOW_ADMIN_URL=http://!ip_add!:5010/api/v1 >> "!DOCKER_COMPOSE_DIR!\.env"
echo DOCUMENT_SERVICE_URL=http://!ip_add!:5006 >> "!DOCKER_COMPOSE_DIR!\.env"

echo Starting forms-flow-webapi container...
!COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up --build -d forms-flow-webapi
if !ERRORLEVEL! neq 0 (
    echo ERROR: Failed to start forms-flow-webapi
    pause
    exit /b !ERRORLEVEL!
)
echo Waiting for API to initialize...
timeout /t 10 /nobreak >nul

REM Setup Web
echo Setting up forms-flow-web...
echo Starting forms-flow-web container...
echo GRAPHQL_API_URL=http://!ip_add!:5500/queries >> "!DOCKER_COMPOSE_DIR!\.env"
!COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up --build -d forms-flow-web
if !ERRORLEVEL! neq 0 (
    echo ERROR: Failed to start forms-flow-web
    pause
    exit /b !ERRORLEVEL!
)
echo Waiting for web interface to initialize...
timeout /t 10 /nobreak >nul

REM Setup Data Layer
echo Setting up forms-flow-data-layer...
echo DEBUG=false >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMSFLOW_DATA_LAYER_WORKERS=4 >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMSFLOW_DATALAYER_CORS_ORIGINS=* >> "!DOCKER_COMPOSE_DIR!\.env"
echo KEYCLOAK_ENABLE_CLIENT_AUTH=false >> "!DOCKER_COMPOSE_DIR!\.env"
echo KEYCLOAK_URL_REALM=forms-flow-ai >> "!DOCKER_COMPOSE_DIR!\.env"
echo JWT_OIDC_JWKS_URI=http://!ip_add!:8080/auth/realms/forms-flow-ai/protocol/openid-connect/certs >> "!DOCKER_COMPOSE_DIR!\.env"
echo JWT_OIDC_ISSUER=http://!ip_add!:8080/auth/realms/forms-flow-ai >> "!DOCKER_COMPOSE_DIR!\.env"
echo JWT_OIDC_AUDIENCE=forms-flow-web >> "!DOCKER_COMPOSE_DIR!\.env"
echo JWT_OIDC_CACHING_ENABLED=True >> "!DOCKER_COMPOSE_DIR!\.env"

echo FORMSFLOW_API_DB_URL=postgresql://postgres:changeme@!ip_add!:6432/webapi >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMSFLOW_API_DB_HOST=!ip_add! >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMSFLOW_API_DB_PORT=6432 >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMSFLOW_API_DB_USER=postgres >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMSFLOW_API_DB_PASSWORD=changeme >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMSFLOW_API_DB_NAME=webapi >> "!DOCKER_COMPOSE_DIR!\.env"

echo FORMIO_DB_URI=mongodb://admin:changeme@!ip_add!:27018/formio?authMechanism=SCRAM-SHA-1^&authSource=admin >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMIO_DB_HOST=!ip_add! >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMIO_DB_PORT=27018 >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMIO_DB_USERNAME=admin >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMIO_DB_PASSWORD=changeme >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMIO_DB_NAME=formio >> "!DOCKER_COMPOSE_DIR!\.env"
echo FORMIO_DB_OPTIONS= >> "!DOCKER_COMPOSE_DIR!\.env"

echo CAMUNDA_DB_URL=jdbc:postgresql://admin:changeme@!ip_add!:5432/formsflow-bpm >> "!DOCKER_COMPOSE_DIR!\.env"
echo CAMUNDA_DB_USER=admin >> "!DOCKER_COMPOSE_DIR!\.env"
echo CAMUNDA_DB_PASSWORD=changeme >> "!DOCKER_COMPOSE_DIR!\.env"
echo CAMUNDA_DB_HOST=!ip_add! >> "!DOCKER_COMPOSE_DIR!\.env"
echo CAMUNDA_DB_PORT=5432 >> "!DOCKER_COMPOSE_DIR!\.env"
echo CAMUNDA_DB_NAME=formsflow-bpm >> "!DOCKER_COMPOSE_DIR!\.env"

echo Starting forms-flow-data-layer container...
!COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up --build -d forms-flow-data-layer
if !ERRORLEVEL! neq 0 (
    echo ERROR: Failed to start forms-flow-data-layer
    pause
    exit /b !ERRORLEVEL!
)
echo Waiting for forms-flow-data-layer to initialize...
timeout /t 5 /nobreak >nul

REM Setup Documents
echo Setting up forms-flow-documents-api...
echo Starting forms-flow-documents-api container...
!COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up --build -d forms-flow-documents-api
if !ERRORLEVEL! neq 0 (
    echo ERROR: Failed to start forms-flow-documents-api
    pause
    exit /b !ERRORLEVEL!
)
echo Waiting for documents API to initialize...
timeout /t 10 /nobreak >nul

REM Verify installation
echo Verifying installation...
set /a "timeoutSeconds=300"
set /a "elapsedSeconds=0"
set "success=false"

:CheckLoop
echo Checking if services are ready... [!elapsedSeconds!/!timeoutSeconds! seconds]
curl -s -o nul -w "%%{http_code}" "http://!ip_add!:5001/" > temp_status.txt 2>nul
set /p HTTP=<temp_status.txt
del temp_status.txt

if "!HTTP!" == "200" (
  set "success=true"
  goto :InstallVerified
) else (
  if !elapsedSeconds! GEQ !timeoutSeconds! (
      goto :InstallVerified
  )
  timeout /t 10 /nobreak >nul
  set /a "elapsedSeconds+=10"
  goto :CheckLoop
)

:InstallVerified
echo.
if "!success!"=="true" (
    echo ************************************************************
    echo *        formsflow.ai has been successfully installed!     *
    echo ************************************************************
    echo.
    echo Access your formsflow.ai application at: http://!ip_add!:3000
    echo.
) else (
    echo WARNING: Installation verification timed out.
    echo The installation may have completed but services are not responding as expected.
    echo.
    echo Try accessing your formsflow.ai application at: http://!ip_add!:3000
    echo If issues persist, check container logs using:
    echo !COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" logs
    echo.
)

pause
endlocal
exit /b 0
@echo off
setlocal EnableDelayedExpansion

REM ============================================
REM VERSION CONFIGURATION
REM ============================================
set "CE_VERSION=v8.0.0-alpha"
set "EE_VERSION=v8.0.1"
set "FORMS_VERSION=v7.3.0"

REM Docker registry configuration
set "DOCKER_REGISTRY=docker.io"
set "DOCKER_REGISTRY_USER="

echo *******************************************
echo *     formsflow.ai Installation Script    *
echo *******************************************
echo.

REM Detect Docker Compose
set "COMPOSE_COMMAND="
for /f "tokens=*" %%A in ('docker compose version 2^>nul') do set "COMPOSE_COMMAND=docker compose"
if "!COMPOSE_COMMAND!"=="" (
    for /f "tokens=*" %%A in ('docker-compose version 2^>nul') do set "COMPOSE_COMMAND=docker-compose"
)
if "!COMPOSE_COMMAND!"=="" (
    echo ERROR: Neither docker compose nor docker-compose is installed.
    echo Please install Docker Desktop or Docker Engine with Compose.
    pause
    exit /b 1
)
echo Using !COMPOSE_COMMAND!

REM Get Docker version
for /f "tokens=*" %%A in ('docker -v 2^>^&1') do set "docker_info=%%A"
set "docker_version="
for /f "tokens=3 delims= " %%A in ("!docker_info!") do (
    set "docker_version=%%A"
    set "docker_version=!docker_version:,=!"
)
echo Docker version: !docker_version!

:: --- Docker Version Validation ---
set "url=https://forms-flow-docker-versions.s3.ca-central-1.amazonaws.com/docker_versions.html"
set "versionsFile=tested_versions.tmp"
echo Fetching tested Docker versions from !url!...
where curl >nul 2>nul
if errorlevel 1 (
    echo curl not found, skipping version validation.
    goto SkipVersionCheck
)
curl -L -s "%url%" -o "%versionsFile%" 2>nul

if not exist "%versionsFile%" (
    echo Failed to fetch tested versions. Skipping validation.
    goto SkipVersionCheck
)
for %%A in ("%versionsFile%") do set "fileSize=%%~zA"
if !fileSize! LSS 10 (
    echo Downloaded file empty. Skipping validation.
    goto SkipVersionCheck
)

echo Checking if your Docker version is tested...
findstr /C:"%docker_version%" "%versionsFile%" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo Your Docker version %docker_version% is in the tested list.
    del "%versionsFile%" 2>nul
    goto SkipVersionCheck
)
echo WARNING: Your Docker version %docker_version% is not in the tested list!
set /p continue=Do you want to continue anyway? [y/n] 
if /i "!continue!" neq "y" (
    echo Installation cancelled.
    del "%versionsFile%" 2>nul
    exit /b 1
)
del "%versionsFile%" 2>nul
echo Continuing with untested Docker version...
:SkipVersionCheck
echo.

REM --- Detect IP address automatically ---
echo Finding your IP address...
set "ip_add="
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    set "temp_ip=%%a"
    set "temp_ip=!temp_ip: =!"
    echo !temp_ip! | find "127." >nul
    if errorlevel 1 if not defined ip_add (
        set "ip_add=!temp_ip!"
    )
)
if not defined ip_add (
    echo WARNING: Could not automatically detect your IP address.
    set /p "ip_add=Please enter your IP address manually: "
) else (
    echo Detected IP address: !ip_add!
    set /p "confirmIP=Is this correct? [y/n] "
    if /i "!confirmIP!" neq "y" (
        set /p "ip_add=Please enter your correct IP address: "
    )
)
echo IP address set to: !ip_add!
echo.

REM --- Detect architecture ---
echo Detecting system architecture...
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "ARCH=arm64"
) else (
    set "ARCH=amd64"
)
echo Detected architecture: !ARCH!
echo.

REM --- Check Docker OSType ---
set "DOCKER_OSTYPE="
for /f "tokens=2 delims=:" %%o in ('docker info 2^>nul ^| findstr /c:"OSType"') do (
    set "DOCKER_OSTYPE=%%o"
)
if defined DOCKER_OSTYPE (
    set "DOCKER_OSTYPE=!DOCKER_OSTYPE: =!"
)
if /i "!DOCKER_OSTYPE!"=="windows" (
    echo ERROR: Docker is using Windows containers.
    echo Please switch Docker Desktop to "Use Linux containers" and re-run.
    pause
    exit /b 1
)
if "!ARCH!"=="amd64" (
    set "PLATFORM=linux/amd64"
) else (
    set "PLATFORM=linux/arm64/v8"
)
echo Using PLATFORM: !PLATFORM!
echo.

REM --- Select edition ---
echo Select installation type:
echo   1. Open Source (Community Edition)
echo   2. Premium (Enterprise Edition)
set /p "editionChoice=Enter your choice [1-2]: "

REM Properly handle edition selection
if "!editionChoice!"=="2" (
    set "EDITION=ee"
    set "IMAGE_TAG=!EE_VERSION!"
    set "MF_EDITION=ee"
    echo.
    echo ============================================
    echo Selected: Premium ^(Enterprise Edition^)
    echo Version: !EE_VERSION!
    echo ============================================
    echo.
    
    REM --- Docker Login for Enterprise Edition ---
    echo Enterprise Edition requires Docker registry authentication.
    echo.
    
    REM Fixed Docker username for formsflow.ai Enterprise Edition
    set "DOCKER_USERNAME=formsflowaidev"
    
    REM Check if already logged in
    set "CURRENT_USER="
    for /f "tokens=2" %%u in ('docker info 2^>nul ^| findstr "Username:"') do set "CURRENT_USER=%%u"
    
    if defined CURRENT_USER (
        echo Already logged in as: !CURRENT_USER!
        
        if "!CURRENT_USER!"=="!DOCKER_USERNAME!" (
            set /p "useCurrentLogin=Do you want to use the existing login? [y/n] "
            
            if /i "!useCurrentLogin!"=="y" (
                set "NEED_LOGIN=false"
                echo Using existing Docker login.
            ) else (
                echo Logging out from current session...
                docker logout 2>nul
                set "NEED_LOGIN=true"
            )
        ) else (
            echo Note: Enterprise Edition requires logging in as '!DOCKER_USERNAME!'
            set /p "switchAccount=Do you want to switch accounts? [y/n] "
            
            if /i "!switchAccount!"=="y" (
                echo Logging out from current session...
                docker logout 2>nul
                set "NEED_LOGIN=true"
            ) else (
                echo WARNING: Current user may not have access to Enterprise Edition images.
                echo Continuing with current login, but installation may fail.
                set "NEED_LOGIN=false"
            )
        )
    ) else (
        set "NEED_LOGIN=true"
    )
    
    if "!NEED_LOGIN!"=="true" (
        echo.
        echo ============================================
        echo Docker Registry Login Required
        echo ============================================
        echo Username: !DOCKER_USERNAME!
        echo.
        echo Please enter your access token ^(password^):
        echo Note: Your input will be hidden for security
        echo.
        
        REM Use PowerShell for secure password input
        for /f "usebackq delims=" %%p in (`powershell -Command "$p = Read-Host 'Access Token' -AsSecureString; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p))"`) do set "DOCKER_TOKEN=%%p"
        
        echo.
        echo Logging in to Docker registry as !DOCKER_USERNAME!...
        echo !DOCKER_TOKEN!| docker login -u "!DOCKER_USERNAME!" --password-stdin 2>nul | findstr /C:"Login Succeeded" >nul
        
        if !ERRORLEVEL! EQU 0 (
            echo √ Successfully logged in to Docker registry!
            echo.
        ) else (
            echo.
            echo ============================================
            echo ERROR: Docker login failed!
            echo ============================================
            echo.
            echo Possible reasons:
            echo   1. Invalid access token
            echo   2. Token has expired
            echo   3. Account doesn't have Enterprise Edition access
            echo.
            echo Please verify your token and try again.
            echo If you don't have access, contact your administrator
            echo or use Community Edition ^(Option 1^).
            echo.
            pause
            exit /b 1
        )
    )
    
) else (
    set "EDITION=ce"
    set "IMAGE_TAG=!CE_VERSION!"
    set "MF_EDITION="
    echo.
    echo ============================================
    echo Selected: Open Source ^(Community Edition^)
    echo Version: !CE_VERSION!
    echo ============================================
    echo.
)

REM --- Locate docker-compose files ---
echo Locating docker-compose files...
set "COMPOSE_FILE="
set "ANALYTICS_COMPOSE_FILE="

if exist "..\docker-compose\docker-compose.yml" (
    set "COMPOSE_FILE=..\docker-compose\docker-compose.yml"
    set "DOCKER_COMPOSE_DIR=..\docker-compose"
    echo Found docker-compose.yml.
)
if exist "!DOCKER_COMPOSE_DIR!\analytics-docker-compose.yml" (
    set "ANALYTICS_COMPOSE_FILE=!DOCKER_COMPOSE_DIR!\analytics-docker-compose.yml"
    echo Found analytics-docker-compose.yml.
)
echo Using compose file: !COMPOSE_FILE!
echo.
if not defined COMPOSE_FILE (
    echo ERROR: Could not find docker-compose file. Expected "..\docker-compose\docker-compose.yml".
    echo Please ensure you are running this installer from the repository root or that the docker-compose files exist.
    pause
    exit /b 1
)

REM --- Set Documents API tag based on architecture ---
if "!ARCH!"=="arm64" (
    set "DOCUMENTS_API_TAG=!IMAGE_TAG!-arm64"
) else (
    set "DOCUMENTS_API_TAG=!IMAGE_TAG!"
)

REM --- Analytics & Data Analysis selections ---
set /p "includeAnalytics=Do you want to include analytics in the installation? [y/n] "
if /i "!includeAnalytics!"=="y" (
    set "analytics=1"
    echo Analytics will be included.
) else (
    set "analytics=0"
    echo Analytics will not be included.
)
echo.
echo Sentiment Analysis enables assessment of sentiments within forms by
echo considering specific topics specified during form creation.
echo The data analysis API provides interfaces for sentiment analysis.
echo.
set /p "includeDataAnalysis=Do you want to include forms-flow-data-analysis-api? [y/n] "
if /i "!includeDataAnalysis!"=="y" (
    set "dataanalysis=1"
    echo Data Analysis API will be included.
) else (
    set "dataanalysis=0"
    echo Data Analysis API will not be included.
)
echo.

REM If analytics requested but analytics compose file is missing, warn and skip analytics
if "!analytics!"=="1" (
    if not defined ANALYTICS_COMPOSE_FILE (
        echo WARNING: analytics compose file not found; skipping analytics setup.
        set "analytics=0"
    )
)

echo.
echo ============================================
echo Installation summary:
echo ============================================
echo - IP Address: !ip_add!
echo - Edition: !EDITION!
echo - Architecture: !ARCH!
echo - PLATFORM: !PLATFORM!
echo - Analytics: !analytics!
echo - Data Analysis: !dataanalysis!
echo ============================================
echo.
set /p "confirmInstall=Begin installation with these settings? [y/n] "
if /i "!confirmInstall!" neq "y" (
    echo Installation cancelled.
    pause
    exit /b 0
)

REM --- Set image names based on edition ---
if "!EDITION!"=="ee" (
    set "IMAGE_SUFFIX=-ee"
) else (
    set "IMAGE_SUFFIX="
)

REM --- Set microfrontend URLs based on edition ---
if "!EDITION!"=="ee" (
    set "MF_WEB_PATH=forms-flow-web/web-ee"
) else (
    set "MF_WEB_PATH=forms-flow-web/web"
)

REM --- Create .env file ---
echo Creating .env file...
(
echo # FormsFlow.ai Configuration
echo # Generated on %date% %time%
echo # Edition: !EDITION!
echo # Version: !IMAGE_TAG!
echo # Architecture: !ARCH!
echo.
echo # Architecture and Platform
echo ARCHITECTURE=!ARCH!
echo PLATFORM=!PLATFORM!
echo.
echo # Edition
echo EDITION=!EDITION!
echo.
echo # Image Names ^(EE editions use -ee suffix^)
echo IMAGE_SUFFIX=!IMAGE_SUFFIX!
echo.
echo # Image Tags
echo IMAGE_TAG=!IMAGE_TAG!
echo FORMS_TAG=!FORMS_VERSION!
echo DOCUMENTS_API_TAG=!DOCUMENTS_API_TAG!
echo.
echo # Microfrontend URLs ^(Commented out by default - uncomment in docker-compose if needed^)
echo MF_FORMSFLOW_WEB_URL=https://forms-flow-microfrontends.aot-technologies.com/!MF_WEB_PATH!@v8.0.0/forms-flow-web.gz.js
echo MF_FORMSFLOW_NAV_URL=https://forms-flow-microfrontends.aot-technologies.com/forms-flow-nav@v8.0.0/forms-flow-nav.gz.js
echo MF_FORMSFLOW_SERVICE_URL=https://forms-flow-microfrontends.aot-technologies.com/forms-flow-service@v8.0.0/forms-flow-service.gz.js
echo MF_FORMSFLOW_COMPONENTS_URL=https://forms-flow-microfrontends.aot-technologies.com/forms-flow-components@v8.0.0/forms-flow-components.gz.js
echo MF_FORMSFLOW_ADMIN_URL=https://forms-flow-microfrontends.aot-technologies.com/forms-flow-admin@v8.0.0/forms-flow-admin.gz.js
echo MF_FORMSFLOW_REVIEW_URL=https://forms-flow-microfrontends.aot-technologies.com/forms-flow-review@v8.0.0/forms-flow-review.gz.js
echo MF_FORMSFLOW_SUBMISSIONS_URL=https://forms-flow-microfrontends.aot-technologies.com/forms-flow-submissions@v8.0.0/forms-flow-submissions.gz.js
echo.
echo # Database Configuration
echo KEYCLOAK_JDBC_DB=keycloak
echo KEYCLOAK_JDBC_USER=admin
echo KEYCLOAK_JDBC_PASSWORD=changeme
echo FORMIO_DB_USERNAME=admin
echo FORMIO_DB_PASSWORD=changeme
echo FORMIO_DB_NAME=formio
echo CAMUNDA_JDBC_USER=admin
echo CAMUNDA_JDBC_PASSWORD=changeme
echo CAMUNDA_JDBC_DB_NAME=formsflow-bpm
echo FORMSFLOW_API_DB_USER=postgres
echo FORMSFLOW_API_DB_PASSWORD=changeme
echo FORMSFLOW_API_DB_NAME=webapi
echo DATA_ANALYSIS_DB_USER=general
echo DATA_ANALYSIS_DB_PASSWORD=changeme
echo DATA_ANALYSIS_DB_NAME=dataanalysis
echo.
echo # Keycloak Configuration
echo KEYCLOAK_ADMIN_USER=admin
echo KEYCLOAK_ADMIN_PASSWORD=changeme
echo KEYCLOAK_URL=http://!ip_add!:8080
echo KEYCLOAK_URL_REALM=forms-flow-ai
echo KEYCLOAK_URL_HTTP_RELATIVE_PATH=/auth
echo KEYCLOAK_BPM_CLIENT_ID=forms-flow-bpm
echo KEYCLOAK_BPM_CLIENT_SECRET=e4bdbd25-1467-4f7f-b993-bc4b1944c943
echo KEYCLOAK_WEB_CLIENT_ID=forms-flow-web
echo KEYCLOAK_ENABLE_CLIENT_AUTH=false
echo.
echo # API URLs
echo FORMIO_DEFAULT_PROJECT_URL=http://!ip_add!:3001
echo FORMSFLOW_API_URL=http://!ip_add!:5001
echo BPM_API_URL=http://!ip_add!:8000/camunda
echo DOCUMENT_SERVICE_URL=http://!ip_add!:5006
echo DATA_ANALYSIS_URL=http://!ip_add!:6001
echo DATA_ANALYSIS_API_BASE_URL=http://!ip_add!:6001
echo.
echo # Application Configuration
echo APPLICATION_NAME=formsflow.ai
echo LANGUAGE=en
echo NODE_ENV=production
echo.
echo # Security
echo WEBSOCKET_ENCRYPT_KEY=giert989jkwrgb@DR55
echo FORMIO_JWT_SECRET=---- change me now ---
echo FORM_EMBED_JWT_SECRET=f6a69a42-7f8a-11ed-a1eb-0242ac120002
echo.
echo # Redis
echo REDIS_ENABLED=false
echo REDIS_URL=redis://redis:6379/0
echo.
echo # Feature Flags
echo MULTI_TENANCY_ENABLED=false
echo CUSTOM_SUBMISSION_ENABLED=false
echo DRAFT_ENABLED=false
echo EXPORT_PDF_ENABLED=false
echo PUBLIC_WORKFLOW_ENABLED=false
echo ENABLE_FORMS_MODULE=true
echo ENABLE_TASKS_MODULE=true
echo ENABLE_DASHBOARDS_MODULE=true
echo ENABLE_PROCESSES_MODULE=true
echo ENABLE_APPLICATIONS_MODULE=true
echo ENABLE_APPLICATIONS_ACCESS_PERMISSION_CHECK=false
echo.
echo # Formio Configuration
echo FORMIO_ROOT_EMAIL=admin@example.com
echo FORMIO_ROOT_PASSWORD=changeme
echo NO_INSTALL=1
echo.
echo # Camunda Configuration
echo CAMUNDA_JDBC_URL=jdbc:postgresql://forms-flow-bpm-db:5432/formsflow-bpm
echo CAMUNDA_JDBC_DRIVER=org.postgresql.Driver
echo CAMUNDA_APP_ROOT_LOG_FLAG=error
echo.
echo # Database Connection Strings
echo FORMSFLOW_API_DB_URL=postgresql://postgres:changeme@forms-flow-webapi-db:5432/webapi
echo FORMSFLOW_API_DB_HOST=forms-flow-webapi-db
echo FORMSFLOW_API_DB_PORT=5432
echo.
echo # Additional Configuration
echo APP_SECURITY_ORIGIN=*
echo FORMSFLOW_API_CORS_ORIGINS=*
echo CONFIGURE_LOGS=true
echo API_LOG_ROTATION_WHEN=d
echo API_LOG_ROTATION_INTERVAL=1
echo API_LOG_BACKUP_COUNT=7
echo DATE_FORMAT=DD-MM-YY
echo TIME_FORMAT=hh:mm:ss A
echo USER_NAME_DISPLAY_CLAIM=preferred_username
echo ENABLE_COMPACT_FORM_VIEW=false
echo.
echo # Worker Configuration
echo GUNICORN_WORKERS=5
echo GUNICORN_THREADS=10
echo GUNICORN_TIMEOUT=120
echo FORMSFLOW_DATA_LAYER_WORKERS=4
) > "!DOCKER_COMPOSE_DIR!\.env"

echo .env file created successfully!
echo.

REM --- Start Keycloak first ---
echo ***********************************************
echo *        Starting Keycloak container...        *
echo ***********************************************

!COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up -d keycloak keycloak-db keycloak-customizations
if errorlevel 1 (
    echo ERROR: Failed to start Keycloak.
    echo If this is an authentication error, please check your Docker login credentials.
    pause
    exit /b 1
)
echo Waiting for Keycloak to initialize...
timeout /t 25 /nobreak >nul
echo Keycloak is up.
echo.

REM --- Start Analytics (if selected) ---
if "!analytics!"=="1" (
    if defined ANALYTICS_COMPOSE_FILE (
        call :ConfigureRedash
        if errorlevel 1 (
            echo ERROR: Failed to configure or start analytics.
            pause
            exit /b 1
        )
    ) else (
        echo WARNING: analytics compose file not found; skipping analytics setup.
    )
)

REM --- Start Main Stack ---
echo ***********************************************
echo *       Starting Main FormsFlow Stack...       *
echo ***********************************************

if "!dataanalysis!"=="1" (
    echo Starting all services including Data Analysis API...
    call !COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up -d
) else (
    echo Starting core services ^(excluding Data Analysis API^)...
    call !COMPOSE_COMMAND! -p formsflow-ai -f "!COMPOSE_FILE!" up -d keycloak keycloak-db keycloak-customizations forms-flow-forms-db forms-flow-webapi forms-flow-webapi-db forms-flow-bpm forms-flow-bpm-db forms-flow-forms forms-flow-documents-api forms-flow-data-layer forms-flow-web redis
)
if errorlevel 1 (
    echo.
    echo ERROR: Failed to start main containers.
    echo.
    if "!EDITION!"=="ee" (
        echo This might be an authentication issue. Please verify:
        echo 1. You are logged in to Docker registry: docker login
        echo 2. Your account has access to Enterprise Edition images
        echo 3. You can manually pull an image: docker pull formsflow/forms-flow-webapi-ee:!IMAGE_TAG!
        echo.
        echo For access to Enterprise Edition, please contact your administrator.
    )
    pause
    exit /b 1
)

echo.
echo ============================================
echo formsflow.ai installation completed successfully!
echo ============================================
echo.
echo Access points:
echo   - FormsFlow Web: http://!ip_add!:3000
echo   - Keycloak:      http://!ip_add!:8080/auth
echo   - API:           http://!ip_add!:5001
echo   - BPM:           http://!ip_add!:8000
if "!dataanalysis!"=="1" (
    echo   - Data Analysis: http://!ip_add!:6001
)
if "!analytics!"=="1" (
    echo   - Analytics:     http://!ip_add!:7001
)
echo.
echo Default credentials:
echo   - Username: admin
echo   - Password: changeme
echo.
echo Edition installed: !EDITION! ^(!ARCH!^)
echo Version: !IMAGE_TAG!
echo Forms Version: !FORMS_VERSION!
echo.
pause
endlocal
exit /b 0

:ConfigureRedash
REM Subroutine to configure and start Redash analytics
echo ***********************************************
echo *     Configuring Analytics (Redash)...       *
echo ***********************************************

REM Use the same configuration as the working script
set "REDASH_HOST=http://!ip_add!:7001"
set "PYTHONUNBUFFERED=0"
set "REDASH_LOG_LEVEL=INFO"
set "REDASH_REDIS_URL=redis://redis:6379/0"
set "POSTGRES_USER=postgres"
set "POSTGRES_PASSWORD=changeme"
set "POSTGRES_DB=postgres"
set "REDASH_COOKIE_SECRET=redash-selfhosted"
set "REDASH_SECRET_KEY=redash-selfhosted"
set "REDASH_DATABASE_URL=postgresql://postgres:changeme@postgres/postgres"
set "REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN=*"
set "REDASH_REFERRER_POLICY=no-referrer-when-downgrade"
set "REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS=Content-Type, Authorization"

echo Configuring Redash...

REM Add Redash configuration to .env file
echo.>>"!DOCKER_COMPOSE_DIR!\.env"
echo # Redash Analytics Configuration>>"!DOCKER_COMPOSE_DIR!\.env"
echo REDASH_HOST=!REDASH_HOST!>>"!DOCKER_COMPOSE_DIR!\.env"
echo PYTHONUNBUFFERED=!PYTHONUNBUFFERED!>>"!DOCKER_COMPOSE_DIR!\.env"
echo REDASH_LOG_LEVEL=!REDASH_LOG_LEVEL!>>"!DOCKER_COMPOSE_DIR!\.env"
echo REDASH_REDIS_URL=!REDASH_REDIS_URL!>>"!DOCKER_COMPOSE_DIR!\.env"
echo POSTGRES_USER=!POSTGRES_USER!>>"!DOCKER_COMPOSE_DIR!\.env"
echo POSTGRES_PASSWORD=!POSTGRES_PASSWORD!>>"!DOCKER_COMPOSE_DIR!\.env"
echo POSTGRES_DB=!POSTGRES_DB!>>"!DOCKER_COMPOSE_DIR!\.env"
echo REDASH_COOKIE_SECRET=!REDASH_COOKIE_SECRET!>>"!DOCKER_COMPOSE_DIR!\.env"
echo REDASH_SECRET_KEY=!REDASH_SECRET_KEY!>>"!DOCKER_COMPOSE_DIR!\.env"
echo REDASH_DATABASE_URL=!REDASH_DATABASE_URL!>>"!DOCKER_COMPOSE_DIR!\.env"
echo REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN=!REDASH_CORS_ACCESS_CONTROL_ALLOW_ORIGIN!>>"!DOCKER_COMPOSE_DIR!\.env"
echo REDASH_REFERRER_POLICY=!REDASH_REFERRER_POLICY!>>"!DOCKER_COMPOSE_DIR!\.env"
echo REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS=!REDASH_CORS_ACCESS_CONTROL_ALLOW_HEADERS!>>"!DOCKER_COMPOSE_DIR!\.env"

echo Redash configuration complete.
echo.

echo ***********************************************
echo *     Creating Analytics Database...           *
echo ***********************************************
echo Creating analytics database...
call !COMPOSE_COMMAND! -p formsflow-ai -f "!ANALYTICS_COMPOSE_FILE!" run --rm server create_db
if errorlevel 1 (
    echo WARNING: Database creation may have failed, but continuing...
)

echo ***********************************************
echo *        Starting Analytics Containers...      *
echo ***********************************************
call !COMPOSE_COMMAND! -p formsflow-ai -f "!ANALYTICS_COMPOSE_FILE!" up -d
if errorlevel 1 (
    echo ERROR: Failed to start analytics containers.
    echo Please check the logs with: docker logs redash
    exit /b 1
)

echo Waiting for Analytics (Redash) to initialize...
timeout /t 15 /nobreak >nul

echo.
echo ============================================
echo Redash is now running at: http://!ip_add!:7001
echo ============================================
echo.
echo IMPORTANT: To complete Redash setup:
echo 1. Open http://!ip_add!:7001 in your browser
echo 2. Create an admin account
echo 3. Go to Settings -^> API Key to generate an API key
echo 4. Copy the API key for the next step
echo.

REM Add INSIGHT_API_URL to .env
echo INSIGHT_API_URL=http://!ip_add!:7001>>"!DOCKER_COMPOSE_DIR!\.env"

REM Prompt for API key
set /p "INSIGHT_API_KEY=Enter your Redash API key: "
echo INSIGHT_API_KEY=!INSIGHT_API_KEY!>>"!DOCKER_COMPOSE_DIR!\.env"
echo API key saved to .env file.

exit /b 0
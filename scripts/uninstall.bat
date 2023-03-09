@echo off

set /p choice=Do you want to uninstall formsflow.ai installation? [y/n]
if %choice%==y (
    set /a uninstall=1
) else (
    set /a uninstall=0
)

if %uninstall%==1 (
    call:main
)

echo ********************** formsflow.ai is successfully uninstalled ****************************


EXIT /B %ERRORLEVEL%


:: ================&&&&&&===  Functions  ====&&&&&&&&&============================

:: #############################################################
:: ################### Main Function ###########################
:: #############################################################

:main
    call:forms-flow-all ..\docker-compose
    call:forms-flow-analytics ..\docker-compose
    call:prune-docker
    call:clear-dir ..\docker-compose\configuration
    call:clear-env ..\docker-compose
    EXIT /B 0
   
:: #############################################################
:: ################### forms-flow-forms ########################
:: #############################################################

:forms-flow-all

    if exist %~1 (
        docker-compose -f %~1\docker-compose.yml down
	)
    EXIT /B 0

:: #############################################################
:: ################### forms-flow-analytics ########################
:: #############################################################

:forms-flow-analytics

    if exist %~1 (
        docker-compose -f %~1\analytics-docker-compose.yml down
	)
    EXIT /B 0

:: ##############################################################
:: ##############################################################

:clear-dir
    if exist %~1 (
        del /Q /S "config.js"
   EXIT /B 0

:clear-env
    if exist %~1 (
        del /Q /S ".env"
   EXIT /B 0
	
:: #############################################################
:: ############# clearing dangling images ######################
:: #############################################################

:prune-docker
    docker volume prune -f
    set images="31557345b2e8" "68141167a247" "8a7391477d59" "59baa6e3d1a8" "176399451347" "a12419875629" "360e5a526f8d"
    (for %%a in (%images%) do ( 
         docker rmi %%a -f
    ))

# Changelog for forms-flow-ai-Deployment

Mark  items as `Added`, `Changed`, `Fixed`, `Removed`, `Untested Features`, `Upcoming Features`, `Known Issues`

## 5.3.0 - 2023-11-24

`Added`

*  Data-analysis-api service into docker-compose file.
*  Added IP confirmation check to confirm the user IP.
*  Added `Docker engine` versions that are tested and working fine.
*  Added `docker-compose` file for Enterprise edition.

`Modified`

*  Updated batch script by adding tested docker-versions
*  Updated shell script for better understanding.
*  Modified the environment variables.

`Upcoming Features`

* An update will be introduced to provide users with the option to run the data analysis API, making it an optional feature.
* An update in the script to enable a quick installation process specifically tailored for enterprise edition users.

## 5.2.0 - 2023-07-07

`Added`

*  Added `Label-Name` for images to easily uninstall images using label name.
*  Added a checkpoint for webapi to check whether it runs in the browser.
*  Added `DB-port` for keycloak.
*  Added `Documents-api` container as a new feature in quick installation.


`Modified`

*  Updated web-api port from `5000` to `5001`
*  Updated Redash image 
*  Updated the docker-compose by including networks for all containers.
*  Updated the `ENV` variables for Web


`Removed`

*  Removed the `config.js` file since it is directly taken through image.


## 5.1.1 - 2023-05-18


`Added`

* `docker-compose` Seperate Docker-compose file has added for windows, and Mac.
*  Added IP confirmation to avoid IP issues.
*  Added CI/CD pipeline.


`Modified`

*  Reduced script size
*  Fixed versions for databases

# Changelog for forms-flow-ai-Deployment

Mark  items as `Added`, `Changed`, `Fixed`, `Removed`, `Untested Features`, `Upcoming Features`, `Known Issues`

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
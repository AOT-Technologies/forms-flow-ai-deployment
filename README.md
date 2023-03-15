# Download and Installation

In the following document, we’ll describe about the different project dependencies, and the installation options being supported.

## Table of Contents

- [Download and Installation](#download-and-installation)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Download the formsflow.ai](#download-the-formsflowai)
  - [Installation](#installation)
    - [Docker Based Installation](#docker-based-installation)
      - [Docker single click installation](#docker-single-click-installation)
      - [Docker Full Deployment](#docker-full-deployment)
    - [Openshift Based Installation](#openshift-based-installation)
      - [Openshift Full Deployment](#openshift-full-deployment)
  - [Verifying the Installation status](#verifying-the-installation-status)


## Prerequisites

* Admin access to a local or remote server (can be local Windows PC or Mac provided it is **64**-bit with at least **16GB** RAM and **25GB** HDD) 
* For docker based installation [Docker](https://docker.com) needs to be installed.
  * For **Mac**, make sure the [docker for mac](https://docs.docker.com/docker-for-mac/#resources) memory allocation is set to at least **16GB**. 

## Download the formsflow.ai

* Clone this github repo:  https://github.com/AOT-Technologies/forms-flow-ai-deployment.git

## Installation

There are multiple options for installing formsflow.ai. They are given below

- Docker Based installation
  - [Docker single click installation](#docker-single-click-installation)
  - [Docker Full Deployment](#Docker-Full-Deployment)
- Openshift Based Installation
  - [Openshift Full Deployment](#Openshift-Full-Deployment)

### Docker Based Installation

------------------
#### Docker single click installation

Follow the instructions in the [documentation](https://aot-technologies.github.io/forms-flow-ai-doc/#quick_installation) and run the install.bat/bash for [quick installation](https://github.com/AOT-Technologies/forms-flow-ai-deployment/tree/main/scripts).

#### Docker Full Deployment

Follow the instructions on [docker installation guide](./docs/docker-compose/README.md)
 
 
### Openshift Based Installation

------------------
#### Openshift Full Deployment

 Follow the instructions on [openshift installation guide](./docs/helm/README.md)
 
## Verifying the Installation status

> The following applications will be started and can be accessed in your browser.

 Srl No | Service Name | Usage | Access | Default credentials (userName / Password)|
--- | --- | --- | --- | --- 
1|`Keycloak`|Authentication|`http://localhost:8080`| `admin/changeme`
2|`forms-flow-forms`|form.io form building. This must be started earlier for resource role id's creation|`http://localhost:3001`|`admin@example.com/changeme`
3|`forms-flow-analytics`|Redash analytics server, This must be started earlier for redash key creation|`http://localhost:7001`|Use the credentials used for registration / [Default user credentials](./docs/forms-flow-ai-properties.md)
4|`forms-flow-web`|formsflow Landing web app|`http://localhost:3000`|[Default user credentials](./docs/forms-flow-ai-properties.md)
5|`forms-flow-api`|API services|`http://localhost:5000`|`Authorization tocken from keycloak role based user credentials`
6|`forms-flow-bpm`|Camunda integration|`http://localhost:8000/camunda`| [Default user credentials](./docs/forms-flow-ai-properties.md) 

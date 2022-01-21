# local_reliability_dev_scripts

## Don't sweat the small stuff
Please remember to not sweat the small stuff, and how do you not sweat the small stuff?

You turn everything into code of course.

Various portions can be copied of this repo can be copied into other repos.

These are meant to be modified, so consider these are inspirations and other starting points
for creating your own tools for speeding up your own dev processes.

Scripts that can be used to help with Local Reliability Chores

## Getting started
### Step 1: setup initial connection
```
invoke-build init
```

### Requirements
#### Files you should create yourself
* Makefile.creds.build.ps1 - if you would like to access the database for various environments
* sql_server_cmd_input.sql - Database sql command to run

#### Invoke-Build
* Most of the Reliability team is standardized on Powershell (Powershell is assumed)
* Invoke-Build is installed
```
Install-Module InvokeBuild -Scope CurrentUser
Install-Module InvokeBuild
```
#### Scoop
* `Scoop` is a command that is used
```
iwr -useb get.scoop.sh | iex
```

### Directory Structure

* aws/          - Sample Config files
* aws/amplify/
* aws/cloudwatch/
* aws/glue/
* aws/logs/
* filevine/
* filevine/audit/
* gitlab/
* localstack/
* redis/
* terraform/    - Example Makefile build file that can be exported to a directory that works on our existing pipeline
* Makefile.build.ps1 - See notes below

#### Makefile.build.ps1
This is using the `Invoke-Build`

Support for:
* AWS
  * Logs
    * Insights - not tested
    * tail / watch
  * S3
    * Directory Search
    * Download File
      * File helper to view json files
  * EC2
    * Find System by name
    * SSM into system (Windowws systems)
  * ECR
    * Login
  * Elasticache
    * Describe Replica Groups
  * Glue
    * Stop Glue Job
    * Glue Job Run Status
    * Glue Query

* SQL (command line)
  * Why launch bulky client, when you only need to log into CLI
    * Save commands for future searches

* Terraform helper setup
  * setup code to install helper files to a specific directory to allow for local testing

* Redis - CLI (docker instance)

* Git
  * Push

* Gitlab
  * glab

* Docker
  * Check Images
  * Tag Images
  * Push Images

* helper functions to convert date time into unix timestamps

* Runbooks
  * Audit

## Add your files


## Integrate with your tools


## Test and Deploy
* None is currently necessary on a pipeline build side ...

# Editing this README


## Suggestions for a good README

## Name
Local Dev Tool Scripts for Reliability

## Description
Helps setup terraform on a local level so you don't have to wait for the build pipeline to confirm if your code works.


## Installation

## Usage

## Support

## Roadmap
* [ ] Write up documentation on how to use invoke-build helper
* [ ] Write up documentation around how to use local terraform helper scripts
* [ ] Presentation on Local terraform development

## Contributing
Feel free to contribute, just be sure to gear them toward local development configurations

## Authors and acknowledgment
* Abby Malson (SRE)

## License
For open source projects, say how it is licensed.

## Project status
* actively being worked on (feel free to contribute

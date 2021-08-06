# Sendy for Docker

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/eric-mathison/docker-sendy/Build%20Docker%20Image%20and%20Push?style=for-the-badge)

Ready, set, send! Sendy is prepackaged with Apache and PHP in this Docker image.

## What is Sendy?

[Sendy](https://sendy.co/?ref=V997H) is a self hosted email newsletter application that lets you send trackable emails via Amazon Simple Email Service (SES).

[![sendy](https://cdn.sendy.co/sendy-report17-dark@2x.jpg)](https://sendy.co/?ref=V997H)

**Sendy requires a license to operate.**  
[You can get a license here](https://sendy.co/?ref=V997H)

## Setting up Sendy

### Starting a Sendy Container to connect with your MySQL (MariaDB) Server

```bash
docker run --rm --name sendy -e SENDY_FQDN=localhost -e MYSQL_HOST=localhost -e MYSQL_USER=sendy -e MYSQL_PASSWORD=sendypassword -e MYSQL_DATABASE=sendy -d ericmathison/sendy:latest
```

### Using Docker Compose

```yaml
version: "3.9"
services:
    # MySQL Database
    sendy-db:
        image: ericmathison/mariadb:latest
        volumes:
            - db-data:/var/lib/mysql
        environment:
            MYSQL_ROOT_PASSWORD: "rootpassword"
            MYSQL_DATABASE: "sendy"
            MYSQL_USER: "sendy"
            MYSQL_PASSWORD: "sendypassword"

    # Sendy Webapp
    sendy:
        image: ericmathison/sendy:latest
        depends_on:
            - sendy-db
        environment:
            SENDY_FQDN: "localhost"
            MYSQL_HOST: "sendy-db"
            MYSQL_USER: "sendy"
            MYSQL_PASSWORD: "sendypassword"
            MYSQL_DATABASE: "sendy"
            SENDY_PROTOCOL: "http"
        ports:
            - 80:80

volumes:
    db-data:
```

## Configuration

### Environment Variables

#### Required

`SENDY_FQDN`: The full domain where Sendy will be hosted _without http:// or https:// ie. domain.com_
`MYSQL_HOST`: The address of your MySQL database server
`MYSQL_USER`: The user name for the MySQL database
`MYSQL_PASSWORD`: The password for the MySQL user
`MYSQL_DATABASE`: The name of the MySQL database

#### Optional

`SENDY_PROTOCOL`: Specify whether your site is http or https _Defaults to https_
`MYSQL_PORT`: The port to access your MySQL database _Defaults to 3306_

### Cron Jobs

There are 3 cron jobs currently setup.

1. `Schedule Campaigns` - Checks to see if there are any campaigns to send out. _Runs every 5 minutes_
2. `Autoresponders` - Checks to see if it's time to send any drip emails _Runs every minute_
3. `CSV Imports` - Checks to see if there are any csv lists to import _Runs every minute_

### GH Actions

This repo is configured to automatically build this Docker image and upload it to your Docker Hub account.

1. To setup this action, you need to set the following environment secrets in your repo:

-   `DOCKERHUB_USERNAME` - this is your Docker Hub username
-   `DOCKERHUB_TOKEN` - this is your Docker Hub API key

2. You need to update the tags for the build in `/.github/workflows/deploy.yml` on line 26.

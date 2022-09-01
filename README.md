[![CircleCI](https://circleci.com/gh/sul-dlss/dor-services-app.svg?style=svg)](https://circleci.com/gh/sul-dlss/dor-services-app)
[![Maintainability](https://api.codeclimate.com/v1/badges/955223f2386ae5f10e33/maintainability)](https://codeclimate.com/github/sul-dlss/dor-services-app/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/955223f2386ae5f10e33/test_coverage)](https://codeclimate.com/github/sul-dlss/dor-services-app/test_coverage)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app.svg)](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app)
[![OpenAPI Validator](http://validator.swagger.io/validator?url=https://raw.githubusercontent.com/sul-dlss/dor-services-app/main/openapi.yml)](http://validator.swagger.io/validator/debug?url=https://raw.githubusercontent.com/sul-dlss/dor-services-app/main/openapi.yml)

# DOR Services App

This Ruby application provides a REST API for DOR Services.
There is a [OAS 3.0 spec](http://spec.openapis.org/oas/v3.0.2) that documents the
API in [openapi.yml](openapi.yml).  You can browse the generated documentation at [http://sul-dlss.github.io/dor-services-app/](http://sul-dlss.github.io/dor-services-app/)

## Authentication

To generate an authentication token run `RAILS_ENV=production bin/rails generate_token` on the prod server.
This will use the HMAC secret to sign the token. It will ask you to submit a value for "Account".  This should be the name of the calling service, or a username if this is to be used by a specific individual.  This value is used for traceability of errors and can be seen in the "Context" section of a Honeybadger error.  For example:

```
{"invoked_by" => "workflow-service"}
```

## Developer Notes

DOR Services App is a Rails app.

### Background Jobs

Dor Services App uses Sidekiq to process background jobs, which requires Redis. You can either install this locally, if running services locally, or run it via `docker-compose`. To spin up Sidekiq, run:

```shell
bundle exec sidekiq # use -d option to daemonize/run in the background
```

See the output of `bundle exec sidekiq --help` for more information.

Note that the application has a web UI for monitoring Sidekiq activity at `/queues`.

## Running Tests

NOTE: you need to be running at least Ruby 2.7.4 in order for the tests to pass (using the cocina factories).

First, ensure the database container is spun up:

```shell
docker compose up db # use -d to daemonize/run in background
```

And if you haven't yet prepared the test database, run:

```shell
RAILS_ENV=test bundle exec rails db:test:prepare
```

To run the tests:

  `bundle exec rspec`

To run rubocop:

  `bundle exec rubocop`

## Console and Development Server

### Using Docker

First, you'll need both Docker and docker-compose installed.

Run dor-services-app and its dependencies using:

```shell
docker compose up -d
```

#### Update Docker image

```shell
docker build -t suldlss/dor-services-app:latest .
docker push suldlss/dor-services-app:latest
```

### Without Docker

First you'll need to setup configuration files to connect to a valid Fedora and SOLR instance.  See the "config/settings.yml" file for a template.  Create a folder called "config/settings" and then copy that settings.yml file and rename it for the environment you wish to setup (e.g. "config/settings/development.local.yml").

Edit this file to add the appropriate URLs.  You may also need certs to talk to actual Fedora servers.  Once you have this file in place, you can start your Rails server or console in development mode:

To spin up a local rails console:

  `bundle exec rails c`

To spin up a local development server:

  `bundle exec rails s`

## Setup RabbitMQ
You must set up the durable rabbitmq queues that bind to the exchange where workflow messages are published.

```sh
RAILS_ENV=production bin/rake rabbitmq:setup
```
This is going to create queues for this application that bind to some topics.

## RabbitMQ queue workers
In a development environment you can start sneakers this way:
```sh
WORKERS=CreateEventJob bin/rake sneakers:run
```

but on the production machines we use systemd to do the same:
```sh
sudo /usr/bin/systemctl start sneakers
sudo /usr/bin/systemctl stop sneakers
sudo /usr/bin/systemctl status sneakers
```

This is started automatically during a deploy via capistrano


## Other tools

### Running Reports

There is information about how to run reports on the sdr-infra VM in the [cocina-models README](https://github.com/sul-dlss/cocina-models#running-reports-in-dsa).  This approach has two advantages:
- sdr-infra connects to the DSA database as read-only
- no resource competition with production DSA processing

### Generating a list of druids from Solr query
```
$ bin/generate-druid-list 'is_governed_by_ssim:"info:fedora/druid:rp029yq2361"'
```

The results are written to `druids.txt`.

### Removing deleted items from a list of druids
$ bin/clean-druid-list -h
Usage: bin/clean-druid-list [options]
    -i, --input FILENAME             File containing list of druids (instead of druids.txt).
    -o, --output FILENAME            File to write list of druids (instead of druids.clean.txt).
    -h, --help                       Displays help.

Solr is used to determine if an item still exists.

### Find druids missing from the SOLR index

Run the missing druid rake task:
```
RAILS_ENV=production bundle exec rake missing_druids:unindexed_objects
```
This produces a `missing_druids.txt` file in the application root.

Missing druids can be indexed with:
```
RAILS_ENV=production bundle exec rake missing_druids:index_unindexed_objects
```

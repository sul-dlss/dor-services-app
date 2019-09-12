[![CircleCI](https://circleci.com/gh/sul-dlss/dor-services-app.svg?style=svg)](https://circleci.com/gh/sul-dlss/dor-services-app)
[![Coverage Status](https://coveralls.io/repos/github/sul-dlss/dor-services-app/badge.svg?branch=master)](https://coveralls.io/github/sul-dlss/dor-services-app?branch=master)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app.svg)](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app)
[![Docker image](https://images.microbadger.com/badges/image/suldlss/dor-services-app.svg)](https://microbadger.com/images/suldlss/dor-services-app "Get your own image badge on microbadger.com")

# DOR Services App

This Ruby application provides a REST API for DOR Services.
There is a (OAS 3.0 spec)[http://spec.openapis.org/oas/v3.0.2] that documents the
API in [openapi.json].  If you clone this repo, you can view this by opening [docs/index.html].

## Authentication

To generate an authentication token run `rake generate_token` on the prod server.
This will use the HMAC secret to sign the token. It will ask you to submit a value for "Account".  This should be the name of the calling service, or a username if this is to be used by a specific individual.  This value is used for traceability of errors and can be seen in the "Context" section of a Honeybadger error.  For example:

```
{"invoked_by" => "workflow-service"}
```

## Seeding the staging environment

It's possible to clear out and re-seed the staging environment by using the following rake task:

```
./bin/rake delete_all_objects
```

This will load all the FOXML from https://github.com/sul-dlss/dor-services-app/blob/master/lib/tasks/seeds/


## Developer Notes

DOR Services App is a Rails app.

## Running Tests

To run the tests:

  `bundle exec rake`

To run rubocop separately (auto run with tests):

  `bundle exec rake rubocop`

## Console and Development Server

### Using Docker

First, you'll need both Docker and docker-compose installed.

Run dor-services-app and its dependencies using:

```shell
docker-compose up -d
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

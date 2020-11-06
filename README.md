[![CircleCI](https://circleci.com/gh/sul-dlss/dor-services-app.svg?style=svg)](https://circleci.com/gh/sul-dlss/dor-services-app)
[![Maintainability](https://api.codeclimate.com/v1/badges/955223f2386ae5f10e33/maintainability)](https://codeclimate.com/github/sul-dlss/dor-services-app/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/955223f2386ae5f10e33/test_coverage)](https://codeclimate.com/github/sul-dlss/dor-services-app/test_coverage)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app.svg)](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app)
[![Docker image](https://images.microbadger.com/badges/image/suldlss/dor-services-app.svg)](https://microbadger.com/images/suldlss/dor-services-app "Get your own image badge on microbadger.com")
[![OpenAPI Validator](http://validator.swagger.io/validator?url=https://raw.githubusercontent.com/sul-dlss/dor-services-app/master/openapi.yml)](http://validator.swagger.io/validator/debug?url=https://raw.githubusercontent.com/sul-dlss/dor-services-app/master/openapi.yml)

# DOR Services App

This Ruby application provides a REST API for DOR Services.
There is a [OAS 3.0 spec](http://spec.openapis.org/oas/v3.0.2) that documents the
API in [openapi.yml](openapi.yml).  You can browse the generated documentation at [http://sul-dlss.github.io/dor-services-app/](http://sul-dlss.github.io/dor-services-app/)

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

### Background Jobs

Dor Services App uses Sidekiq to process background jobs, which requires Redis. You can either install this locally, if running services locally, or run it via `docker-compose`. To spin up Sidekiq, run:

```shell
bundle exec sidekiq # use -d option to daemonize/run in the background
```

See the output of `bundle exec sidekiq --help` for more information.

Note that the application has a web UI for monitoring Sidekiq activity at `/queues`.

## Running Tests

First, ensure the database container is spun up:

```shell
docker-compose up db # use -d to daemonize/run in background
```

And if you haven't yet prepared the test database, run:

```shell
RAILS_ENV=test rails db:test:prepare
```

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

## Test Cocina mappings
Given the tremendous heterogeneity of existing Fedora data, it is helpful to test mappings against actual production data. However, due to the slowness of retrieving from Fedora, creating a local cache of Fedora data is helpful.

Several tools (described below) assist with creating a local cache and performing the testing.

These tools are best run on a server within the network. (Currently installed on `sdr-deploy.stanford.edu`).

### Setup
1. Create a `settings.local.yml` containing:

        ssl:
          cert_file: "tls/certs/dor-services-prod-dor-prod.crt"
          key_file: "tls/private/dor-services-prod-dor-prod.key"

        fedora_url: 'https://sul-dor-prod.stanford.edu/fedora'

        solr:
          url: 'https://sul-solr.stanford.edu/solr/argo3_prod'
2. Copy certificates locally:

        scp -r <user from puppet>@<dor serices production host>:/etc/pki/tls .

### Create a list of random druids
```
bin/generate-druid-list 100000
```

This will create `druids.txt`, containing a list of druids. If the file already exists, the existing druids will be used and new druids will be added to it.

Note that the druids are unique.

### Create a list of all druids
Alternatively, a comprehensive list of druids can be generated by querying Fedora's DB.

On the Fedora server, get the MySQL password from `~/.fedora.my.cnf`.

```
mysql --user=fedora --password fedora -e "select doPID from doRegistry where doPID like 'druid:%';" -N | cut -c 1-17 > druids.txt
```
You will be prompted to provide the password.

### Seed the cache
```
bin/generate-cache 100000
```

Using the druids from `druids.txt`, this will retrieve the item from Fedora and store the objects, datastreams, and disseminations in the `cache` directory.

### Validate mapping to Cocina from Fedora
```
bin/validate-to-cocina 100000
```

Using the druids from `druids.txt` and the cache, this will map the Fedora item to the Cocina model and record any errors.

Errors are returned ordered by the number of items that raised that error. For example:
```
41 of 500 (8.2%)
Error: undefined method `text' for nil:NilClass (32 errors)
Examples: druid:qb322bg3331, druid:vd938vg1826, druid:kc373zp2312, druid:gx497tb8747, druid:zq244qv7198, druid:pd738nx3263, druid:qm576pd0390, druid:tp743yv4651, druid:md775pw3650, druid:xw600sw0934
Error: key not found: "Other version"
Did you mean?  "otherVersion" (4 errors)
Examples: druid:vx162kw9911, druid:rh979yv1005, druid:qb797px1044, druid:fq225gc7097
```

A complete set of results will be written to `results.txt`.

Note that the validation is parallelized, so it is much faster than the other processes.

### Running the validation on sdr-deploy

First indicate in the #dlss-infrastructure slack channel you will be running validation.
Then, get on VPN, ssh into the sdr-deploy server, check out your branch, and run the validation.

Note that you should ensure nobody else is currently running a validation, as you will be checking out a branch
in a common directory.  As a best practice, re check-out the master branch when done to indicate it is not in use.

```
ssh deploy@sdr-deploy.stanford.edu
cd /opt/app/deploy/dor-services-app
git branch # see if you are on master, which shows likely not in use
git fetch
git checkout YOUR_BRANCH_NAME
bin/validate-to-cocina 350000
```

When done, delete your branch and change back to master:
```
git checkout master
git branch -d YOUR_BRANCH_NAME
```

When done, you may want to fetch the `results.txt` to your local drive (it is written to the root folder of dor-services-app)
and look for errors.

```
scp deploy@sdr-deploy.stanford.edu:~/dor-services-app/results.txt results-oct30.txt
grep Error results-oct30.txt # shows the unique errors
```

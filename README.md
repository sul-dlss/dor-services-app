[![CircleCI](https://circleci.com/gh/sul-dlss/dor-services-app.svg?style=svg)](https://circleci.com/gh/sul-dlss/dor-services-app)
[![Maintainability](https://api.codeclimate.com/v1/badges/955223f2386ae5f10e33/maintainability)](https://codeclimate.com/github/sul-dlss/dor-services-app/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/955223f2386ae5f10e33/test_coverage)](https://codeclimate.com/github/sul-dlss/dor-services-app/test_coverage)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app.svg)](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app)
[![Docker image](https://images.microbadger.com/badges/image/suldlss/dor-services-app.svg)](https://microbadger.com/images/suldlss/dor-services-app "Get your own image badge on microbadger.com")
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

## Seeding the staging environment

It's possible to clear out and re-seed the staging environment by using the following rake task:

```
./bin/rake delete_all_objects
```

This will load all the FOXML from https://github.com/sul-dlss/dor-services-app/blob/main/lib/tasks/seeds/


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
```
ssl:
  cert_file: "tls/certs/dor-services-prod-dor-prod.crt"
  key_file: "tls/private/dor-services-prod-dor-prod.key"

fedora_url: 'https://sul-dor-prod.stanford.edu/fedora'

solr:
  url: 'https://sul-solr.stanford.edu/solr/argo3_prod'

dor_services:
  url: 'https://dor-services-prod.stanford.edu'
  token: '<create a token>'
```
  
2. Copy certificates locally via `scp -r <user from puppet>@<dor services production host>:/etc/pki/tls .`

### Create a list of all druids
A comprehensive list of druids can be generated by querying Fedora's DB.

On the Fedora server, get the MySQL password from `~/.fedora.my.cnf`.

```
mysql --user=fedora --password fedora -e "select doPID from doRegistry where doPID like 'druid:%';" -N | cut -c 1-17 > druids.txt
```
You will be prompted to provide the password.

### Seed the cache
```
$ bin/generate-cache -h
Usage: bin/generate-cache [options]
    -s, --sample SAMPLE              Sample size, otherwise all druids.
    -o, --overwrite                  Overwrite cache for item if exists.
    -r, --random                     Select random druids.
    -a, --auto                       Automatically choose sample based on 14 day cycle.
    -d, --druids DRUIDS              List of druids (instead of druids.txt).
    -i, --input INPUT                Input filename, otherwise druids.txt.
    -k, --skip SKIP                  Number of druids to skip.    
    -h, --help                       Displays help.

$ bin/generate-cache
```

Using the druids from `druids.txt`, this will retrieve the item from Fedora and store the objects, datastreams, and disseminations in the `cache` directory.

Alternatively, to get a single druid:
```
$ bin/generate-cache -d druid:bh164hd2167
druid:bh164hd2167 (1)
```

### Keep the cache up to date.
`bin/cache-o-matic.sh` will query Solr to find objects that have been updated in the last day, update the cache, and add the items to `druids.txt`.

This script can be run from a cron job to keep the cache up to date. It is currently being run on sdr-deploy.

### Copy cache
Rather than generating a local cache (which is slow), cache files can be copied from the cache on sdr-deploy (which is fast).

```
$ bin/copy-cache -h
Usage: bin/copy-cache [options]
    -s, --sample SAMPLE              Sample size, otherwise all druids.
    -d, --druids DRUIDS              List of druids (instead of druids.txt).
    -i, --input INPUT                Input filename, otherwise druids.txt.
    -h, --help                       Displays help.

$ bin/copy-cache -i druids.testbed.txt -s 1000
To copy cache:
rsync --files-from=cache-files.txt deploy@sdr-deploy.stanford.edu:/opt/app/deploy/dor-services-app .
```

### Validate mapping to Cocina from Fedora
```
$ bin/validate-cocina-roundtrip -h
Usage: bin/validate-cocina-roundtrip [options]
    -s, --sample SAMPLE              Sample size, otherwise all druids.
    -u, --update                     Run object update instead of object create.
    -r, --random                     Select random druids.
    -f, --no_content                 Without content metadata (fast).
    -n, --no_descriptive             Without descriptive metadata.
    -d, --druids DRUIDS              List of druids (instead of druids.txt).
    -i, --input FILENAME             File containing list of druids (instead of druids.txt).
    -h, --help                       Displays help.

$ bin/validate-cocina-roundtrip -s 100
Testing |Time: 00:00:21 | ============================================================================ | Time: 00:00:21
Status (n=100; not using Missing for success/different/error stats):
  Success:   8 (8.0%)
  Different: 56 (56.0%)
  Mapping error:     36 (36.0%)
  Update error:     0 (0.0%)
  Missing:     0 (0.0%)
```

Using the druids from `druids.txt` and the cache, this will create a Fedora item, map the Fedora item to the Cocina model, create a new Fedora item from the Cocina object, map the new Fedora item to the Cocina model, and compare the original Cocina object against the new Cocina object and the original Fedora item against the new Fedora item.

### Validate mapping to Cocina from MODS (descriptive metadata only)
```
$ bin/validate-to-desc-cocina -h
Usage: bin/validate-to-desc-cocina [options]
    -s, --sample SAMPLE              Sample size, otherwise all druids.
    -u, --unique-filename            Result file named for branch and runtime
    -a, --apo                        Include APO in report (slower).
    -i, --input FILENAME             File containing list of druids (instead of druids.txt).
    -d, --druids DRUIDS              List of druids (instead of druids.txt).
    -h, --help                       Displays help.

$ bin/validate-to-desc-cocina -s 10
Testing |Time: 00:00:00 | ===================================================================== | Time: 00:00:00

Error: 0 of 10 (0.0%)%)
Data error: 0 of 10 (0.0%)%)
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

Note that the location of the cache can be set with `FEDORA_CACHE` environment variable.

### Validate mapping to MODS from Cocina (descriptive metadata only)
```
$ bin/validate-to-mods -h
Usage: bin/validate-to-mods [options]
    -s, --sample SAMPLE              Sample size, otherwise all druids.
    -u, --unique-filename            Result file named for branch and runtime
    -i, --input FILENAME             File containing list of druids (instead of druids.txt).    
    -h, --help                       Displays help.

$ bin/validate-to-mods
Testing |Time: 00:00:06 | ============================================================= | Time: 00:00:06
To Fedora error: 21 of 7500 (0.28%)
To Cocina error: 0 of 7500 (0.0%)
Data error: 4 of 7500 (0.05333333333333334%)
Missing: 26 of 7500 (0.3466666666666667%)
```

This is similar to `bin/validate-to-desc-cocina` but reports errors raised when mapping to Fedora.

Note that the location of the cache can be set with `FEDORA_CACHE` environment variable.

### Validate roundtrip mapping (to Cocina from MODS then to Fedora from MODS -- descriptive metadata only)
```
$ bin/validate-desc-cocina-roundtrip -h
Usage: bin/validate-desc-cocina-roundtrip [options]
    -s, --sample SAMPLE              Sample size, otherwise all druids.
    -r, --random                     Select random druids.
    -f, --fast                       Do not write results files.
    -d, --druids DRUIDS              List of druids (instead of druids.txt).
    -i, --input FILENAME             File containing list of druids (instead of druids.txt).    
    -h, --help                       Displays help.

$ bin/validate-desc-cocina-roundtrip -s 10 -r
```

Using the druids from `druids.txt` and the cache, this will compare the differences between the original MODS (Fedora descriptive metadata) and the roundtripped MODS.

Alternatively, to map a single druid:
```
$ bin/validate-desc-cocina-roundtrip -d druid:bh164hd2167
```

Errors totals are summarized. For example:
```
Status (n=100):
  Success:   54 (54.0%)
  Different: 45 (45.0%)
  To Cocina error:     0 (0.0%)
  To Fedora error:     0 (0.0%)
  Missing:     1 (1.0%)
```

In addition, detailed results for each item with a difference are provided in an individual file in `results/`.

Note that the location of the cache can be set with `FEDORA_CACHE` environment variable.

### Validate mapping to Cocina from MODS (rights metadata only)
```
$ bin/validate-rights-cocina-roundtrip -h
Usage: bin/validate-rights-cocina-roundtrip [options]
    -s, --sample SAMPLE              Sample size, otherwise all druids.
    -r, --random                     Select random druids.
    -d, --druids DRUIDS              List of druids (instead of druids.txt).
    -i, --input FILENAME             File containing list of druids (instead of druids.txt).
    -h, --help                       Displays help.

$ bin/validate-rights-cocina-roundtrip -s 10
Testing |Time: 00:00:00 | ==================================================================================== | Time: 00:00:00
Status (n=10; not using Missing for success/different/error stats):
  Success:   8 (100.0%)
  Different: 0 (0.0%)
  To Cocina error:     0 (0.0%)
  To Fedora error:     0 (0.0%)
  Missing (no rightsMetadata):     2 (20.0%)
```

### Running the validation on sdr-deploy

All of these directions required that you be sshed into sdr-deploy server.
```
$ ssh deploy@sdr-deploy.stanford.edu
```

To setup an environment for testing, clone your own copy of the repo as shown below:
```
$ mkdir jlit
$ cd jlit
$ git clone https://github.com/sul-dlss/dor-services-app.git
$ cd dor-services-app
$ cp ../../dor-services-app/druids.txt .
```

Note that all environments share a cache by default:
```
$ echo $FEDORA_CACHE
/opt/app/deploy/dor-services-app/cache
```

Test with `bin/validate-cocina-roundtrip`, comparing results from main against your branch. The sample size to you is up to you; bigger samples are recommended for more complex changes.

```
$ git checkout main
$ git pull
$ bin/validate-desc-cocina-roundtrip -s 350000 -f
$ git checkout YOUR_BRANCH_NAME
$ bin/validate-desc-cocina-roundtrip -s 350000 -f
```

When running `bin/validate-to-desc-cocina` or `bin/validate-to-mods`, you may want to fetch the `results.txt` to your local drive (it is written to the root folder of dor-services-app)
and look for errors.

```
$ scp deploy@sdr-deploy.stanford.edu:~/jlit/dor-services-app/results.txt results-oct30.txt
$ grep Error results-oct30.txt # shows the unique errors
```

## Other tools
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

### Refreshing descriptive metadata
```
$ bin/refresh-metadata
```

The list of druids is read from `refresh.txt`.

Successes are written to `refresh-success.txt`. Errors are written to `refresh-error.txt` (druids only) and `refresh-error.log` (druids and error messages).

The script handles Symphony's nightly downtime.

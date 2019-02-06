[![Build Status](https://travis-ci.org/sul-dlss/dor-services-app.png?branch=master)](https://travis-ci.org/sul-dlss/dor-services-app)
[![Coverage Status](https://coveralls.io/repos/github/sul-dlss/dor-services-app/badge.svg?branch=master)](https://coveralls.io/github/sul-dlss/dor-services-app?branch=master)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app.svg)](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app)
[![Docker image](https://images.microbadger.com/badges/image/suldlss/dor-services-app.svg)](https://microbadger.com/images/suldlss/dor-services-app "Get your own image badge on microbadger.com")

# DOR Services App

This Ruby application provides a REST API for DOR Services. [View the REST API documentation](https://consul.stanford.edu/display/chimera/REST+mappings+for+dor-services+gem).

## Developer Notes

DOR Services App is a Rails app.

Because the workflows that the app provides access to use Oracle on the backend, the app requires
the Oracle client gem, [ruby-oci8](https://github.com/kubo/ruby-oci8). In order to install
ruby-oci8, you need to go through a couple of hoops to set up an Oracle client. The easiest approach
is to install the Oracle Instant Client.   Read detailed instructions for installing with homebrew at
http://www.rubydoc.info/github/kubo/ruby-oci8/file/docs/install-on-osx.md or follow directions below.

1. Download the "Instant Client Package - Basic" and the "Instant Client Package - SDK" from the
[Oracle download page](http://www.oracle.com/technetwork/topics/intel-macsoft-096467.html)
(requires a free Oracle account).

2. Unzip the downloaded zip files into a directory on your computer. For example (version numbers may be different):

        mkdir /opt/oracle_instantclient/
        cd /opt/oracle_instantclient/
        unzip instantclient-basic-macos.x64-11.2.0.4.0.zip
        unzip instantclient-sdk-macos.x64-11.2.0.4.0.zip

3. Make a symlink to libclntsh.dylib:

        cd /opt/oracle_instantclient/instantclient_11_2
        ln -s libclntsh.dylib.11.1 libclntsh.dylib

4. Set the DYLD\_LIBRARY\_PATH environment variable to point to the recently created Instant Client
directory:

   `export DYLD_LIBRARY_PATH=/opt/oracle_instantclient/instantclient_11_2`

You should now be ready to run `bundle install`. Note that DOR Services App requires Ruby 2.

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


## TODO

We could alter the gemspec of workflow archiver to be platform dependent: only install ruby-oci8 on Linux platforms

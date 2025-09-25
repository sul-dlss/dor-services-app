[![CircleCI](https://circleci.com/gh/sul-dlss/dor-services-app.svg?style=svg)](https://circleci.com/gh/sul-dlss/dor-services-app)
[![codecov](https://codecov.io/github/sul-dlss/dor-services-app/graph/badge.svg?token=MCMiin7aeE)](https://codecov.io/github/sul-dlss/dor-services-app)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app.svg)](https://badge.fury.io/gh/sul-dlss%2Fdor-services-app)
[![OpenAPI Validator](https://validator.swagger.io/validator?url=https://raw.githubusercontent.com/sul-dlss/dor-services-app/main/openapi.yml)](http://validator.swagger.io/validator/debug?url=https://raw.githubusercontent.com/sul-dlss/dor-services-app/main/openapi.yml)

# DOR Services App

This Ruby application provides a REST and GraphQL API for DOR Services.
There is a [OAS 3.0 spec](http://spec.openapis.org/oas/v3.0.2) that documents the
API in [openapi.yml](openapi.yml).  You can browse the generated documentation at [http://sul-dlss.github.io/dor-services-app/](http://sul-dlss.github.io/dor-services-app/)

## Authentication

To generate an authentication token run `RAILS_ENV=production bin/rails generate_token` on the prod server.
This will use the HMAC secret to sign the token. It will ask you to submit a value for "Account".  This should be the name of the calling service, or a username if this is to be used by a specific individual.  This value is used for traceability of errors and can be seen in the "Context" section of a Honeybadger error.  For example:

```
{"invoked_by" => "workflow-service"}
```

## GraphQL
DSA exposes a limited GraphQL API at the `/graphql` endpoint. The API is implemented using [graphql-ruby](https://graphql-ruby.org). The purpose of the API is to allow retrieving only the parts of cocina objects that are needed, in particular, to avoid retrieving very large structural metadata.

It is limited in that:
* It only supports querying, not mutations.
* Only the first level of attributes (description, structural, etc.) are expressed in the GraphQL schema; the contents of each of these attributes are just typed as JSON.

Developer notes:
* Most GraphQL code is in `app/graphql`.
* In local development, the [GraphiQL browser](https://github.com/graphql/graphiql) is available at http://localhost:3000/graphiql.

## Developer Notes

DOR Services App is a Rails app.

### Background Jobs

Dor Services App uses Sidekiq to process background jobs. To spin up Sidekiq, run:

```shell
bundle exec sidekiq # use -d option to daemonize/run in the background
```

See the output of `bundle exec sidekiq --help` for more information.

Note that the application has a web UI for monitoring Sidekiq activity at `/queues`.

## Running Tests

First, ensure the database container is spun up:

```shell
docker compose up # use -d to daemonize/run in background
```

And if you haven't yet prepared the test database, run:

```shell
RAILS_ENV=test bundle exec rails db:test:prepare
```

To run the tests:

  `bundle exec rspec`

To run rubocop:

  `bundle exec rubocop`

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

## Cron check-ins

Some cron jobs (configured via the `whenever` gem) are integrated with Honeybadger check-ins. These cron jobs will check-in with HB (via a curl request to an HB endpoint) whenever run. If a cron job does not check-in as expected, HB will alert.

Cron check-ins are configured in the following locations:

1. `config/schedule.rb`: This specifies which cron jobs check-in and what setting keys to use for the checkin key. See this file for more details.
2. `config/settings.yml`: Stubs out a check-in key for each cron job. Since we may not want to have a check-in for all environments, this stub key will be used and produce a null check-in.
3. `config/settings/production.yml` in `shared_configs`: This contains the actual check-in keys.
4. HB notification page: Check-ins are configured per project in HB. To configure a check-in, the cron schedule will be needed, which can be found with `bundle exec whenever`. After a check-in is created, the check-in key will be available. (If the URL is `https://api.honeybadger.io/v1/check_in/rkIdpB` then the check-in key will be `rkIdpB`).

## Reindexing all objects

A full reindex can be invoked with `bundle exec rake indexer:reindex_jobs`.

This will enqueue a number of `BatchReindexJob`s.

A full reindex is scheduled to happen periodically to make sure that all objects have the latest indexing.

## Robots

DSA hosts robots that perform DSA actions. This replaces the previous pattern in which a common accessioning robot would invoke a DSA endpoint that would start a DSA job that would perform the action and then update the workflow status.

Robots are in `jobs/robots/*`. All DSA robots must be added to Workflow Server Rails' `QueueService` so that the workflow jobs are handled by DSA robots (instead of normal robots).

There also must be a sidekiq process to handle the DSA robot queues. For example:
```
:labels:
 - robot
:concurrency: 5
:queues:
  - [accessionWF_default_dsa, 2]
  - accessionWF_low_dsa
```

## Workflows
The previous independent Rails-based workflow service has been [merged into Dor Services App](https://github.com/sul-dlss-labs/engineering-design-adrs/blob/main/0023-merge-workflow-service.md), and access to it's methods are provided by dor-services-client. The workflow database and robot queues continue to be separate from DSA (meaning that there are separate Postgres and Redis servers for workflow; DSA uses [Rail's multi-database support](https://guides.rubyonrails.org/active_record_multiple_databases.html) and [separate Sidekiq configuration](https://github.com/sul-dlss/dor-services-app/blob/main/config/initializers/sidekiq.rb)).

The workflows are defined by xml templates which are stored in [config/workflows](https://github.com/sul-dlss/dor-services-app/tree/main/config/workflows).  The templates define a dependency graph. When all prerequisites for a step are complete, the step is marked as "queued" and a corresponding job is pushed into Sidekiq.  Some steps are are marked `skip-queue="true"` which means they are merely logged events and do not kick off a Sidekiq process.


### Sidekiq Jobs

When a workflow step is set to done, the service calculates which workflow steps
are ready to be worked on and enqueues Sidekiq jobs for them.  The queues are named
for the workflow and priority.  For example:

```
accessionWF_high
accessionWF_default
accessionWF_low
assemblyWF_high
assemblyWF_default
assemblyWF_low
disseminationWF_high
disseminationWF_default
disseminationWF_low
...
```

#### Workflow Variables

If a workflow or workflows for a particular object require data to be persisted and available between steps, workflow variables can be set.
These are per object/version pair and thus available to any step in any workflow for a given version of an object once set.

These data are not persisted in Cocina, and are not preserved or available outside of the workflow API, so they should only be used to persist information used during workflow processing.

To use, pass in a "context" parameter as JSON in the body of the request when creating a workflow. The json can contain any number of key/value pairs of context.

This context will then be returned as JSON in each `process` block of the XML response containing workflow data for use in processing.

This can be used if a user selects an option in Pre-assembly or Argo that needs to be passed through the accessioning pipeline, such as if OCR or captioning is required.  The value is set when creating the workflow, and then available to each robot which needs it.

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

## Data migrations / bulk remediations

`bin/migrate-cocina` provides a framework for data migrations and bulk remediations. It supports optional versioning and publishing of objects after migration.

```sh
Usage: RAILS_ENV=production bin/migrate-cocina MIGRATION_CLASS [options]
        --mode [MODE]                Migration mode (commit, dryrun, migrate, verify). Default is dryrun
    -p, --processes PROCESSES        Number of processes. Default is 4.
    -s, --sample SAMPLE              Sample size per type, otherwise all objects.
    -h, --help                       Displays help.
```

The process for performing a migration/remediation is:

1. Implement a Migrator (`app/services/migrators/`). See `Migrators::Base` and `Migrators::Exemplar` for the requirements of a Migrator class. Migrators should be unit tested.
2. Perform a dry run: `bin/migrate-cocina Migrators::Exemplar --mode dryrun` and inspect `migrate-cocina.csv` for any errors.  This is a way to change the cocina and validate the new objects without saving the updated cocina or publishing or versioning.
3. Perform migration/remediation: `bin/migrate-cocina Migrators::Exemplar --mode migrate` and inspect `migrate-cocina.csv` for any errors. Commit mode can be used instead of `migrate` when you only want to migrate existing cocina and not open/close versions or create new versions. 
4. Perform verification: `bin/migrate-cocina Migrators::Exemplar --mode verify` and inspect `migrate-cocina.csv` for any errors.  (An error here means that an object matching `.migrate?` has been found ... which is presumably NOT desired after migration.)

Additional notes:

* The dry run and the verification can be performed on `sdr-infra`. See the [existing documentation](https://github.com/sul-dlss/cocina-models#testing-validation-changes) on setting up db connections.
* The migration/remediation must be performed on the DSA server since it requires a read/write DB connection. (`sdr-infra` has a read-only DB connection.)
* Migrations are performed on an ActiveRecord object, not a Cocina object. This allows the remediation of invalid items (i.e., items that cannot be instantiated as Cocina objects).
* Migrations can be performed against all items or just a list provided by the Migrator.
* Breaking changes, especially breaking cocina model changes, are going to require additional steps, e.g., stopping SDR processing. The complete process is to be determined.

## Reset Process (for QA/Stage)

### Steps

1. [Reset the database](https://github.com/sul-dlss/DeveloperPlaybook/blob/main/best-practices/db_reset.md)

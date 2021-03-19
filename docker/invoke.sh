#!/bin/sh

# Don't allow this command to fail
set -e

echo "HOST IS: $DATABASE_HOSTNAME"
until PGPASSWORD=$DATABASE_PASSWORD psql -h "$DATABASE_HOSTNAME" -U $DATABASE_USERNAME -c '\q'; do
    echo "Postgres is unavailable - sleeping"
    sleep 1
done

echo "Postgres is up - Setting up database"

# Allow this command to fail
set +e
echo "Creating DB. OK to ignore errors about test db."
# https://github.com/rails/rails/issues/27299
bin/rails db:create

# Don't allow any following commands to fail
set -e
echo "Migrating db"
bin/rails db:migrate

# Create the Ur-APO ('druid:hv992ry2431') and ensure it's in Solr.
# We can't use the remote indexing service because it depends on dor-services-app being up.
bin/rails runner "Dor::AdminPolicyObject.create!(pid: 'druid:hv992ry2431', label: 'Ur-Apo'); ActiveFedora::SolrService.add(id: 'druid:hv992ry2431', has_model_ssim: 'info:fedora/afmodel:Dor_AdminPolicyObject'); ActiveFedora::SolrService.commit"

echo "Running server"
exec bin/puma -C config/puma.rb config.ru

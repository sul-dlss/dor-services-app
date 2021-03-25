FROM ruby:2.7.2-alpine

# Provide SSL defaults that work in dev/test environments where we do not require connections to secured services
# These values are overrideable at both buildtime and runtime (hence the ARG/ENV combo).
ARG SETTINGS__SSL__CERT_FILE=/app/spec/support/certs/spec.crt
ARG SETTINGS__SSL__KEY_FILE=/app/spec/support/certs/spec.key
ARG SETTINGS__SSL__KEY_PASS=thisisatleast4bytes
ENV SETTINGS__SSL__CERT_FILE="${SETTINGS__SSL__CERT_FILE}"
ENV SETTINGS__SSL__KEY_FILE="${SETTINGS__SSL__KEY_FILE}"
ENV SETTINGS__SSL__KEY_PASS="${SETTINGS__SSL__KEY_PASS}"

# Avoid https://github.com/rails/rails/issues/32451
# This happens when Argo registers an object and dor-services-app calls dor-indexing-app
# which calls back to dor-services-app for the list of AdministrativeTags.
# dor-services-app cannot respond to this second request, so the indexing call times out.
# This probably wouldn't be a problem in Rails 6, but ActiveFedora is preventing that upgrade.
ENV RAILS_ENV=production

# postgresql-client is required for invoke.sh
RUN apk add --update --no-cache  \
  build-base \
  git \
  postgresql-dev \
  postgresql-client \
  shared-mime-info \
  tzdata

# Get bundler 2.0
RUN gem install bundler

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install --without development test

COPY . .

CMD ["./docker/invoke.sh"]

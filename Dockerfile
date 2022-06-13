FROM ruby:3.1.2-alpine

# Provide SSL defaults that work in dev/test environments where we do not require connections to secured services
# These values are overrideable at both buildtime and runtime (hence the ARG/ENV combo).
ARG SETTINGS__SSL__CERT_FILE=/app/spec/support/certs/spec.crt
ARG SETTINGS__SSL__KEY_FILE=/app/spec/support/certs/spec.key
ARG SETTINGS__SSL__KEY_PASS=thisisatleast4bytes
ENV SETTINGS__SSL__CERT_FILE="${SETTINGS__SSL__CERT_FILE}"
ENV SETTINGS__SSL__KEY_FILE="${SETTINGS__SSL__KEY_FILE}"
ENV SETTINGS__SSL__KEY_PASS="${SETTINGS__SSL__KEY_PASS}"

ENV RAILS_ENV=production

# postgresql-client is required for invoke.sh
RUN apk add --update --no-cache  \
  build-base \
  git \
  postgresql-dev \
  postgresql-client \
  tzdata

# Get bundler 2.0
RUN gem install bundler

RUN mkdir -p /app/tmp/pids
WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install --without development test

COPY . .

CMD ["./docker/invoke.sh"]

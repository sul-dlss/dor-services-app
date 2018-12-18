FROM ruby:2.5-stretch

# Provide SSL defaults that work in dev/test environments where we do not require connections to secured services
# These values are overrideable at both buildtime and runtime (hence the ARG/ENV combo).
ARG SETTINGS__SSL__CERT_FILE=/app/spec/support/certs/spec.crt
ARG SETTINGS__SSL__KEY_FILE=/app/spec/support/certs/spec.key
ARG SETTINGS__SSL__KEY_PASS=thisisatleast4bytes
ENV SETTINGS__SSL__CERT_FILE="${SETTINGS__SSL__CERT_FILE}"
ENV SETTINGS__SSL__KEY_FILE="${SETTINGS__SSL__KEY_FILE}"
ENV SETTINGS__SSL__KEY_PASS="${SETTINGS__SSL__KEY_PASS}"

RUN apt-get update -qq && \
    apt-get install -y nano build-essential libsqlite3-dev nodejs

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without production

COPY . .

CMD puma -C config/puma.rb

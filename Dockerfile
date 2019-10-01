FROM ruby:2.5.3-alpine

# Provide SSL defaults that work in dev/test environments where we do not require connections to secured services
# These values are overrideable at both buildtime and runtime (hence the ARG/ENV combo).
ARG SETTINGS__SSL__CERT_FILE=/app/spec/support/certs/spec.crt
ARG SETTINGS__SSL__KEY_FILE=/app/spec/support/certs/spec.key
ARG SETTINGS__SSL__KEY_PASS=thisisatleast4bytes
ENV SETTINGS__SSL__CERT_FILE="${SETTINGS__SSL__CERT_FILE}"
ENV SETTINGS__SSL__KEY_FILE="${SETTINGS__SSL__KEY_FILE}"
ENV SETTINGS__SSL__KEY_PASS="${SETTINGS__SSL__KEY_PASS}"

# postgresql-client is required for invoke.sh
RUN apk --no-cache add \
  postgresql-dev \
  postgresql-client \
  tzdata

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN apk --no-cache add --virtual build-dependencies \
  build-base \
  && bundle install --without production \
  && apk del build-dependencies

COPY . .

CMD ["./docker/invoke.sh"]

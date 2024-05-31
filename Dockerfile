FROM ruby:3.3.1-bookworm

ENV RAILS_ENV=production
ENV BUNDLER_WITHOUT="development test"

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        postgresql-client postgresql-contrib libpq-dev \
        libxml2-dev clang git

# Get bundler 2.0
RUN gem install bundler

RUN mkdir -p /app/tmp/pids
WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

CMD ["./docker/invoke.sh"]

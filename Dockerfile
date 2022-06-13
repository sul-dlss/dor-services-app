FROM ruby:3.1.2-alpine

ENV RAILS_ENV=production
ENV BUNDLER_WITHOUT="development test"

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

RUN bundle install

COPY . .

CMD ["./docker/invoke.sh"]

FROM ruby:2.5-stretch

RUN apt-get update -qq && \
    apt-get install -y nano build-essential libsqlite3-dev nodejs

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without production

COPY . .

CMD puma -C config/puma.rb
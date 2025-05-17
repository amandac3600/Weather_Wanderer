FROM ruby:3.3-slim

LABEL Name=weatherwanderer Version=0.0.1

EXPOSE 3000

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libyaml-dev nodejs

RUN bundle config --global frozen 1

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . /app

CMD ["rails", "server", "-b", "0.0.0.0"]

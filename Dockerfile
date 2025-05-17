FROM ruby:3.3-slim

LABEL Name=weatherwanderer Version=0.0.1

EXPOSE 3000

RUN bundle config --global frozen 1

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . /app

CMD ["ruby", "weatherwanderer.rb"]

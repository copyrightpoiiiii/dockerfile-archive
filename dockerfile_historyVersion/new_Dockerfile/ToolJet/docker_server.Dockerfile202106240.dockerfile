FROM ruby:2.7.3-buster

RUN apt update && apt install -y \
  build-essential  \
  postgresql \
  freetds-dev

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && RAILS_ENV=production bundle install --jobs 20 --retry 5

ENV RAILS_ENV=production

COPY . ./
RUN ["chmod", "755", "docker/entrypoints/server.sh"]
ENTRYPOINT ["./docker/entrypoints/server.sh"]

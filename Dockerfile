FROM ruby:2.1
MAINTAINER "rxacevedo@fastmail.com"

COPY . /usr/src/app
WORKDIR /usr/src/app

RUN bundle install

ENTRYPOINT ["bundle", "exec", "bin/hydan"]

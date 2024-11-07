#!/usr/bin/env bash
# exit on error
set -o errexit

# Install PostgreSQL development files
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y postgresql-client postgresql-server-dev-all build-essential libpq-dev

# Clear tmp/cache
rm -rf tmp/cache/*

export RAILS_ENV=production
export RACK_ENV=production

# Build dependencies with specific pg config
bundle config build.pg --with-pg-config=/usr/bin/pg_config
bundle install --deployment --without development test
bundle exec rake assets:precompile
bundle exec rake db:migrate
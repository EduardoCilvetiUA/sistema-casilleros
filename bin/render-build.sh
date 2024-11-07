#!/usr/bin/env bash
# exit on error
set -o errexit

# Install PostgreSQL development files
apt-get update -qq
apt-get install -y postgresql-client postgresql-server-dev-all build-essential libpq-dev

# Clear tmp/cache
rm -rf tmp/cache/*

# Build dependencies
bundle config build.pg --with-pg-config=/usr/bin/pg_config
bundle config set --local path 'vendor/bundle'

bundle install
bundle exec rake assets:clobber # Clear any old assets
bundle exec rake assets:precompile # Recompile all assets
bundle exec rails db:migrate
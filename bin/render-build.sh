#!/usr/bin/env bash
# exit on error
set -o errexit

# Install PostgreSQL client and development libraries
apt-get update -qq && apt-get install -y postgresql-client libpq-dev

# Clear tmp/cache
rm -rf tmp/cache/*

bundle install
bundle exec rake assets:clobber # Clear any old assets
bundle exec rake assets:precompile # Recompile all assets
bundle exec rails db:migrate
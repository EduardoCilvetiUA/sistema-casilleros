#!/usr/bin/env bash
# exit on error
set -o errexit

# Install system dependencies required for pg gem
curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
apt-get update
apt-get install -y libpq-dev postgresql-client

# Clear tmp/cache
rm -rf tmp/cache/*

# Build gem native extensions with explicit pg config
gem install pg -v '1.5.9' -- --with-pg-config=/usr/bin/pg_config

bundle install
bundle exec rake assets:clobber # Clear any old assets
bundle exec rake assets:precompile # Recompile all assets
bundle exec rails db:migrate
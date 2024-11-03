#!/usr/bin/env bash
# exit on error
set -o errexit

# Only include production files
RAILS_ENV=production bundle install
RAILS_ENV=production bundle exec rails assets:precompile
RAILS_ENV=production bundle exec rails assets:clean
RAILS_ENV=production bundle exec rails db:migrate
#!/usr/bin/env bash
# exit on error
set -o errexit

# Clear tmp/cache
rm -rf tmp/cache/*

bundle install
bundle exec rake assets:clobber # Clear any old assets
bundle exec rake assets:precompile # Recompile all assets
bundle exec rails db:migrate
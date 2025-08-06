#!/bin/bash
set -e

echo "Starting Rails application on Render..."
echo "Running database migrations..."
bundle exec rails db:migrate

echo "Starting Puma server..."
bundle exec puma -C config/puma.rb
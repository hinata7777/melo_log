set -o errexit

# Node.js dependencies installation
npm install

# Build Tailwind CSS
npm run build:css

# Build JavaScript
npm run build

# Ruby dependencies installation
bundle install

# Precompile assets
bundle exec rails assets:precompile

# Clean old assets
bundle exec rails assets:clean

# Run database migrations
bundle exec rails db:migrate
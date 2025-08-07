set -o errexit

bundle install
bundle exec rails assets:precompile  # ← ここでTailwind CSSのビルドが必要
bundle exec rails assets:clean
bundle exec rails db:migrate
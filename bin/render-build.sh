set -o errexit

bundle install
bundle exec rails assets:precompile  # ← ここでTailwind CSSのビルドが必要
bundle exec rails assets:clean
bundle exec rails db:migrate
[ -n "$ADMIN_EMAIL" ] && bundle exec rails runner \
  "u=User.find_by(email: ENV['ADMIN_EMAIL']) or abort('not found'); u.update!(role: :admin); puts 'admin granted'"
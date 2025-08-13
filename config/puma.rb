# config/puma.rb

# Threads
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }.to_i
threads min_threads_count, max_threads_count

# Listen on Render-provided $PORT (必須)
port ENV.fetch("PORT") { 3000 }

# Env
environment ENV.fetch("RACK_ENV") { ENV.fetch("RAILS_ENV") { "production" } }

# Workers（無料枠は 0〜1 推奨。まず 0 でOK）
workers ENV.fetch("WEB_CONCURRENCY", 0).to_i
preload_app!

# （ActiveRecord を使う場合の推奨フック。無害なので入れてOK）
# if defined?(ActiveRecord)
#   before_fork { ActiveRecord::Base.connection_pool.disconnect! }
#   on_worker_boot { ActiveRecord::Base.establish_connection }
# end

# Restart support / PID
plugin :tmp_restart
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

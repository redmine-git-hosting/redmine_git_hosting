stdout_redirect '/home/redmine/redmine/log/puma.stderr.log', '/home/redmine/redmine/log/puma.stdout.log'

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

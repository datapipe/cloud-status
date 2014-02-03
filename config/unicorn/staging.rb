worker_processes 5
preload_app true
listen '/var/unicorn/unicorn.sock'
pid '/var/unicorn/unicorn.pid'
working_directory '/var/www/cloud-status/current'

# timeout any workers that haven't responded in 30 seconds
timeout 30

stderr_path "/var/unicorn/unicorn.stderr.log"
stdout_path "/var/unicorn/unicorn.stdout.log"

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
  old_pid = '/var/unicorn/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "/srv/app/current/Gemfile"
end

after_fork do |server, worker|
  begin
    uid, gid = Process.euid, Process.egid
    user, group = 'admin', 'admin'
    target_uid = Etc.getpwnam(user).uid
    target_gid = Etc.getgrnam(group).gid
    worker.tmp.chown(target_uid, target_gid)
    if uid != target_uid || gid != target_gid
      Process.initgroups(user, target_gid)
      Process::GID.change_privilege(target_gid)
      Process::UID.change_privilege(target_uid)
    end
    defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
    Rails.cache.reconnect
  rescue => e
    raise e
  end
end
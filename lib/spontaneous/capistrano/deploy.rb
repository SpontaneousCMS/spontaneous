
Capistrano::Configuration.instance(:must_exist).load do
  set :normalize_asset_timestamps, false

  set :bundle_cmd,              "bundle"
  set :bundle_flags,            "--deployment --quiet --binstubs --shebang ruby-local-exec"

  set :media_dir,   lambda { "#{deploy_to}/media" }
  set :revision_dir, lambda { "#{deploy_to}/revisions" }

  # namespace :rvm do
  #   task :trust_rvmrc do
  #     run "if [ -f #{release_path}/.rvmrc ];then rvm rvmrc trust #{release_path}; fi"
  #   end
  # end
  #
  # after "deploy", "rvm:trust_rvmrc"

  namespace :spot do
    task :symlink_cache do
      cache_dir = File.join(latest_release, 'cache')
      run "mkdir #{cache_dir}; ln -s #{deploy_to}/media #{cache_dir}; ln -s #{deploy_to}/revisions #{cache_dir}"
    end

    task :symlink_application do
      run "cd #{release_path} && ln -s `bundle show spontaneous`/application public/.spontaneous"
    end
  end

  namespace :deploy do
    task :migrate, :roles => :db do
      spot_env = fetch(:spot_env, "production")
      run "cd #{latest_release} && SPOT_ENV=#{spot_env} ./bin/spot migrate"
    end
  end

  after 'deploy:finalize_update', 'spot:symlink_cache'
  after 'bundle:install', 'spot:symlink_application'
end

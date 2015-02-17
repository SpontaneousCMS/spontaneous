
Capistrano::Configuration.instance(:must_exist).load do
  # TODO: make opts take a list of excludes and turn this into params for the rsync
  def rsync(origin, destination, opts = {})
    cmd = %(rsync -rtDzv --chmod=ugo=rwX -e 'ssh -p #{ssh_options[:port]}' --force #{origin}/ #{destination})
    system cmd
  end

  def remote_directory(server, path)
    "#{user}@#{server}:#{path}"
  end

  namespace :sync do
    desc "Sync the local version to the remote one"
    task :default do
      down
    end

    desc "Sync the remote system to the local one"
    task :up do
      database.up
      media.up
    end

    desc "Sync the local version to the remote one"
    task :down do
      database.down
      media.down
    end

    namespace :database do
      desc "Sync the local database to the server version"
      task :default do
        down
      end

      desc "Sync the local database to the server version"
      task :down do
        puts "  * Syncing database DOWN"
        dumper = Spontaneous::Utils::Database.dumper_for_database
        dumpfilename = ENV['dumpfile'] || dumper.dumpfilename
        run %(cd #{current_path} && #{fetch(:rake)} db:dump dumpfile=#{dumpfilename} )
        dump_file = File.join("tmp", dumpfilename)
        top.download(File.join(current_path, dump_file), dump_file)
        system "bundle exec #{fetch(:rake)} db:load dumpfile=#{dump_file}"
      end

      desc "Sync the server's version of the database to the local one"
      task :up do
        puts "  * Syncing database UP"
        dumper = Spontaneous::Utils::Database.dumper_for_database
        dumpfilename = ENV['dumpfile'] || dumper.dumpfilename
        dump_file = File.join("tmp", dumpfilename)
        dumper.dump(dump_file)
        remote_dump_file = File.join(deploy_to, dumpfilename)
        top.upload(dump_file, remote_dump_file)
        run %(cd #{current_path} && #{fetch(:bundle_cmd, 'bundle')} exec #{fetch(:rake)} db:load dumpfile=#{remote_dump_file} )
      end
    end

    namespace :media do
      desc ""
      task :default do
        down
      end

      desc ""
      task :down do
        roles[:media].each do |server|
          top.rsync(remote_directory(server, media_dir), "cache/media/")
        end
      end

      desc ""
      task :up do
        roles[:media].each do |server|
          top.rsync("cache/media", remote_directory(server, media_dir))
        end
      end
    end
  end
end

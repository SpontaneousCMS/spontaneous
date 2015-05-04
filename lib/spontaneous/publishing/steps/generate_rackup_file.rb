module Spontaneous::Publishing::Steps
  class GenerateRackupFile < BaseStep

    def call
      progress.stage("create server config")
      File.open(config_path, "w:UTF-8") do |file|
        file.write(config)
      end
      progress.step(count, config_path.inspect)
    end

    def count
      1
    end

    def rollback
      FileUtils.rm(config_path) if File.exists?(config_path)
    end

    def config_path
      (site.revision_dir(revision) / "config.ru").tap do |path|
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
      end
    end

    def path
      @path ||= Pathname.new(site.root).realpath.to_s
    end

    def config
      path = Pathname.new(Spontaneous.root).realpath.to_s
      rackup = "config/front.ru"

      template = (<<-RACKUP).gsub(/^ +/, '')
        # This is an automatically generated file *DO NOT EDIT*
        # To configure your Rack application make your changes in
        # '#{path}/#{rackup}'

        # Set the revision to display
        ENV["#{Spontaneous::SPOT_REVISION_NUMBER}"] = "#{revision}"
        ENV["#{Spontaneous::SPOT_ROOT}"] = "#{path}"

        # Change to the absolute path of our application and load the Rack config
        root = "#{path}"
        Dir.chdir(root)
        eval(::File.read("#{rackup}"), binding, ::File.join(root, "#{rackup}"), __LINE__)
      RACKUP
    end
  end
end

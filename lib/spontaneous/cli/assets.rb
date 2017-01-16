module Spontaneous
  module Cli
    class Assets < ::Thor
      include Spontaneous::Cli::TaskUtils

      namespace :assets
      default_task :compile


      desc "compile", "Compiles assets for the Spontaneous UI"

      method_option :destination, type: :string, aliases: "-d", required: true, desc: "Compile assets into DESTINATION"

      def compile(*args)
        compile_assets
      end

      desc "site", "Compiles site assets in preparation for deploy see `config/initializers/assets.rb`"
      method_option :'output-dir', type: :string, aliases: "-d", required: true, desc: "Compile assets into DESTINATION"
      def site(*args)
        compile_site_assets
      end

      protected

      def compile_assets
        prepare(:compile)
        # options[:mode] = :console
        # Find path to install of Spontaneous using bundler and then
        # use this path as params to compiler
        spec = Bundler.load.specs.find{|s| s.name == "spontaneous" }
        p spec.full_gem_path

        compiler = ::Spontaneous::Asset::AppCompiler.new(spec.full_gem_path, options.destination)
        compiler.compile
      end

      def compile_site_assets
        site = prepare!(:compile)
        pre_output_dir = Dir.mktmpdir

        site.deploy_asset_compilation.each do |name, cmd_proc|
          cmd = cmd_proc.call(pre_output_dir)
          say "Compiling assets:", :bold
          say "#{name}: ", :green
          say cmd
          system cmd
        end

        say "Copying assets to output dir:", :bold
        output_dir = options['output-dir']
        ::FileUtils.mkdir_p(output_dir)
        progress = proc { |src, dst|
          say "#{src} ", :blue, false
          say "=> ", nil, false
          say "#{dst}", :green
        }
        compiler = Spontaneous::Asset::Compiler.new(pre_output_dir, output_dir)
        compiler.run(site.deploy_asset_fingerprint, progress)
      end
    end
  end
end


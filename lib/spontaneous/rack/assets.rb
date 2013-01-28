# encoding: UTF-8

module Spontaneous
  module Rack
    module Assets
      module JavaScript
        extend Spontaneous::Output::Assets::Compression

        def self.filetype
          "js"
        end

        def self.extension
          "js"
        end

        def self.compress(filelist)
          compress_js_files(paths(filelist))
        end

        def paths(filelist)
          filelist.map { |file| filepath(file) }.tap do |paths|
            logger.info("Bundling #{paths.length} files")
          end
        end

        def filepath(file)
          File.join(Spontaneous.application_dir, filetype, "#{file}.#{extension}")
        end

        # TODO: remove these
        JQUERY = %w(vendor/jquery)
        COMPATIBILITY = []#%w(compatibility)
        REQUIRE = %w(require)
        LOGIN_JS = %w(login)
        EDITING_JS = %w(spontaneous)
      end

      module CSS
        extend Spontaneous::Output::Assets::Compression

        def self.filetype
          "css"
        end

        def self.extension
          "scss"
        end

        def self.compress(filelist)
          compress_css_files(paths(filelist))
        end

        def paths(filelist)
          filelist.map { |file| filepath(file) }.tap do |paths|
            logger.info("Bundling #{paths.length} files")
          end
        end

        def filepath(file)
          File.join(Spontaneous.application_dir, filetype, "#{file}.#{extension}")
        end

        # TODO: remove these
        LOGIN_CSS = %w(spontaneous) # login
        EDITING_CSS = %w(spontaneous)
        SCHEMA_MODIFICATION_CSS = %w(spontaneous) #schema_error
      end
    end # Assets
  end # Rack
end # Spontaneous

# encoding: UTF-8

require 'shine'
require 'sass'

module Spontaneous
  module Rack
    module Assets

      # module Bundling
      #   extend self

      #   def compress_js(filelist, options={})
      #     shine_compress_files(filelist, :js, options)
      #   end

      #   def compress_css(filelist, options={})
      #     # compress_files(filelist, :css, options)
      #     options = {
      #       :load_paths => [Spontaneous.css_dir],
      #       # :filename => sass_template,
      #       :cache => false,
      #       :style => :compressed
      #     }
      #     paths = paths(filelist)
      #     css = paths.map do |path|
      #       Sass::Engine.for_file(path, options).render
      #     end.join("\\n")
      #     hash = digest(css)
      #     [css, hash]
      #   end

      #   def shine_compress_files(filelist, format, options = {})
      #     paths = paths(filelist)
      #     original_size = filesize(paths)
      #     compressed = Shine::compress_files(paths, format, options)
      #     logger.info("Compressed #{filelist.length} files. Original size #{original_size}, compressed size #{compressed.length}, ratio #{(100*compressed.length.to_f/original_size.to_f).round}%")
      #     hash = digest(compressed)
      #     [compressed, hash]
      #   end

      #   def digest(str)
      #     hash = Digest::SHA1.new.update(str).hexdigest
      #   end

      #   def paths(filelist)
      #     filelist.map { |file| filepath(file) }.tap do |paths|
      #       logger.info("Bundling #{paths.length} files")
      #     end
      #   end

      #   def filepath(file)
      #     File.join(Spontaneous.application_dir, filetype, "#{file}.#{extension}")
      #   end

      #   def filesize(paths)
      #     paths.inject(0) { |sum, path| sum += File.size(path) }
      #   end
      # end
      module JavaScript
        extend Spontaneous::Render::Assets::Compression

        def self.filetype
          "js"
        end

        def self.extension
          "js"
        end

        def self.compress(filelist)
          compress_js(paths(filelist))
        end

        def paths(filelist)
          filelist.map { |file| filepath(file) }.tap do |paths|
            logger.info("Bundling #{paths.length} files")
          end
        end

        def filepath(file)
          File.join(Spontaneous.application_dir, filetype, "#{file}.#{extension}")
        end

        JQUERY = %w(vendor/jquery-1.7.1.min)
        COMPATIBILITY = %w(compatibility)
        REQUIRE = %w(require)
        LOGIN_JS = %w(authentication login)
        EDITING_JS = %w(vendor/jquery-ui-1.8.18.custom.min vendor/JS.Class-2.1.5/min/core vendor/crypto-2.3.0-crypto vendor/crypto-2.3.0-sha1 vendor/diff_match_patch extensions spontaneous properties dom ajax authentication user popover popover_view event_source metadata types image content views views/box_view views/page_view views/piece_view views/page_piece_view entry page_entry box page field field_types/string_field field_types/long_string_field field_types/file_field field_types/image_field field_types/markdown_field field_types/date_field field_types/webvideo_field field_types/select_field content_area preview editing location state panel/root_menu top_bar field_preview box_container progress status_bar upload sharded_upload upload_manager dialogue edit_panel add_home_dialogue page_browser add_alias_dialogue conflicted_field_dialogue  publish services init load)
      end

      module CSS
        extend Spontaneous::Render::Assets::Compression

        def self.filetype
          "css"
        end
        def self.extension
          "scss"
        end

        def self.compress(filelist)
          compress_css(paths(filelist))
        end


        def paths(filelist)
          filelist.map { |file| filepath(file) }.tap do |paths|
            logger.info("Bundling #{paths.length} files")
          end
        end

        def filepath(file)
          File.join(Spontaneous.application_dir, filetype, "#{file}.#{extension}")
        end

        LOGIN_CSS = %w(login)
        EDITING_CSS = %w(v2)
        SCHEMA_MODIFICATION_CSS = %w(schema_error)
      end

    end # Assets
  end # Rack
end # Spontaneous

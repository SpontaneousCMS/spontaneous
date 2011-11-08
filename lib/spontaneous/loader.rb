# encoding: UTF-8

require 'active_support/ordered_hash'

module Spontaneous
  OrderedHash = ActiveSupport::OrderedHash unless defined?(OrderedHash)

  module Loader
    class << self

      def use_reloader?
        Site.config.reload_classes
      end

      def load!
        Reloader.run! if use_reloader?
        Spontaneous.load_paths.each do |path|
          load_classes(path)
        end
      end

      def reload!
        Reloader.reload!
      end

      # thank you oh makers of Merb for your genius
      def load_classes(*paths)
        orphaned_classes = []
        paths.flatten.each do |path|
          Dir[path].sort.each do |file|
            begin
              load_file(file)
            rescue NameError => ne
              # puts "Stashed file with missing requirements for later reloading: #{file}"
              # ne.backtrace.each_with_index { |line, idx| puts "[#{idx}]: #{line}" }
              orphaned_classes.unshift(file)
            end
          end
        end
        load_classes_with_requirements(orphaned_classes)
      end

      def load_file(file)
        if use_reloader?
          Reloader.safe_load(file)
        else
          require(file)
        end
      end

      def load_classes_with_requirements(klasses)
        klasses.uniq!

        while klasses.size > 0
          # Note size to make sure things are loading
          size_at_start = klasses.size

          # List of failed classes
          failed_classes = []
          # Map classes to exceptions
          error_map = {}

          klasses.each do |klass|
            begin
              load_file klass
            rescue NameError => ne
              error_map[klass] = ne
              failed_classes.push(klass)
            end
          end
          klasses.clear

          # Keep list of classes unique
          failed_classes.each { |k| klasses.push(k) unless klasses.include?(k) }

          # Stop processing if nothing loads or if everything has loaded
          if klasses.size == size_at_start && klasses.size != 0
            # Write all remaining failed classes and their exceptions to the log
            messages = error_map.map do |klass, e|
              ["Could not load #{klass}:\n\n#{e.message} - (#{e.class})",
               "#{(e.backtrace || []).join("\n")}"]
            end
            messages.each { |msg, trace| puts("#{msg}\n\n#{trace}") }
            puts "#{failed_classes.join(", ")} failed to load."
          end
          break if(klasses.size == size_at_start || klasses.size == 0)
        end

        nil
      end
    end
    module Reloader
      class << self
        CACHE                = {}
        MTIMES               = {}
        FILES_LOADED         = {}
        LOADED_CLASSES       = {}

        # reset state, mostly used in tests
        def reset!
          CACHE.clear
          MTIMES.clear
          FILES_LOADED.clear
          LOADED_CLASSES.clear
        end
        ##
        # Reload all files with changes detected.
        #
        def reload!
          rotation do |file, mtime|
            # Retrive the last modified time
            new_file = MTIMES[file].nil?
            previous_mtime = MTIMES[file] ||= mtime
            logger.debug "Detected a new file #{file}" if new_file
            # We skip to next file if it is not new and not modified
            next unless new_file || mtime > previous_mtime
            # Now we can reload our file
            safe_load(file, mtime)
          end
        end

        ##
        # Returns true if any file changes are detected and populates the MTIMES cache
        #
        def changed?
          changed = false
          rotation do |file, mtime|
            new_file = MTIMES[file].nil?
            previous_mtime = MTIMES[file] ||= mtime
            changed = true if new_file || mtime > previous_mtime
          end
          changed
        end
        alias :run! :changed?

        ##
        # A safe Kernel::load which issues the necessary hooks depending on results
        #
        def safe_load(file, mtime=nil)
          reload = mtime && mtime > MTIMES[file]

          logger.debug "Reloading #{file}" if reload

          # Removes all classes declared in the specified file
          if klasses = LOADED_CLASSES.delete(file)
            klasses.each { |klass| remove_constant(klass) }
          end

          # Keeps track of which constants were loaded and the files
          # that have been added so that the constants can be removed
          # and the files can be removed from $LOADED_FEAUTRES
          if FILES_LOADED[file]
            FILES_LOADED[file].each do |fl|
              next if fl == file
              $LOADED_FEATURES.delete(fl)
            end
          end

          # Now reload the file ignoring any syntax errors
          $LOADED_FEATURES.delete(file)

          # Duplicate objects and loaded features in the file
          klasses = ObjectSpace.classes.dup
          files_loaded = $LOADED_FEATURES.dup

          # Start to re-require old dependencies
          #
          # Why we need to reload the dependencies i.e. of a model?
          #
          # In some circumstances (i.e. with MongoMapper) reloading a model require:
          #
          # 1) Clean objectspace
          # 2) Reload model dependencies
          #
          # We need to clean objectspace because for example we don't need to apply two times validations keys etc...
          #
          # We need to reload MongoMapper dependencies for re-initialize them.
          #
          # In other cases i.e. in a controller (specially with dependencies that uses autoload) reload stuff like sass
          # is not really necessary... but how to distinguish when it is (necessary) since it is not?
          #
          if FILES_LOADED[file]
            FILES_LOADED[file].each do |fl|
              next if fl == file
              # Swich off for a while warnings expecially "already initialized constant" stuff
              begin
                verbosity = $-v
                $-v = nil
                require(fl)
              ensure
                $-v = verbosity
              end
            end
          end

          # And finally reload the specified file
          begin
            require(file)
          rescue SyntaxError => ex
            logger.error "Cannot require #{file} because of syntax error: #{ex.message}"
          ensure
            MTIMES[file] = mtime if mtime
          end

          # Store the file details after successful loading
          LOADED_CLASSES[file] = ObjectSpace.classes - klasses
          FILES_LOADED[file]   = $LOADED_FEATURES - files_loaded

          nil
        end

        ##
        # Removes the specified class and constant.
        #
        def remove_constant(const)
          # return if Padrino::Reloader.exclude_constants.any? { |base| (const.to_s =~ /^#{base}/ || const.superclass.to_s =~ /^#{base}/) } &&
          # !Padrino::Reloader.include_constants.any? { |base| (const.to_s =~ /^#{base}/ || const.superclass.to_s =~ /^#{base}/) }

          Spontaneous.schema.delete(const)

          parts = const.to_s.split("::")
          base = parts.size == 1 ? Object : Object.full_const_get(parts[0..-2].join("::"))
          object = parts[-1].to_s
          begin
            base.send(:remove_const, object)
          rescue NameError
          end

          nil
        end

        ##
        # Searches Ruby files in your +Padrino.root+ and monitors them for any changes.
        #
        def rotation
          paths = []
          # paths  = Dir[Padrino.root("*")].unshift(Padrino.root).
          #   reject { |path| Padrino::Reloader.exclude.include?(path) || !File.directory?(path) }
          # files  = paths.map { |path| Dir["#{path}/**/*.rb"] }.flatten.uniq

          files = Spontaneous.load_paths.map do |glob|
            Dir[glob]
          end.flatten.uniq

          files.map { |file|
            # next if Padrino::Reloader.exclude.any? { |base| file =~ /^#{base}/ }

            found, stat = figure_path(file, paths)
            next unless found && stat && mtime = stat.mtime

            CACHE[file] = found

            yield(found, mtime)
          }.compact
        end

        ##
        # Takes a relative or absolute +file+ name and a couple possible +paths+ that
        # the +file+ might reside in. Returns the full path and File::Stat for that path.
        #
        def figure_path(file, paths)
          found = CACHE[file]
          found = file if !found and Pathname.new(file).absolute?
          found, stat = safe_stat(found)
          return found, stat if found

          # paths.find do |possible_path|
          #   path = ::File.join(possible_path, file)
          #   found, stat = safe_stat(path)
          #   return ::File.expand_path(found), stat if found
          # end

          return false, false
        end

        def safe_stat(file)
          return unless file
          stat = ::File.stat(file)
          return file, stat if stat.file?
        rescue Errno::ENOENT, Errno::ENOTDIR
          CACHE.delete(file) and false
        end
      end # self

    end
  end # Loader
end # Spontaneous

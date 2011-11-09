# encoding: UTF-8

require 'active_support/ordered_hash'

module Spontaneous
  OrderedHash = ActiveSupport::OrderedHash unless defined?(OrderedHash)

  class Loader
    attr_reader :use_reloader, :load_paths

    alias_method :use_reloader?, :use_reloader

    def initialize(load_paths, use_reloader)
      @load_paths = load_paths
      @use_reloader = use_reloader
    end

    def reloader
      @reloader ||= Reloader.new(load_paths)
    end

    def load!
      reloader.run! if use_reloader?
      load_paths.each do |path|
        load_classes(path)
      end
    end

    def reload!
      reloader.reload!
    end

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
        reloader.safe_load(file)
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

    class Reloader
      attr_reader :load_paths, :cache, :mtimes, :files_loaded, :loaded_classes

      def initialize(load_paths)
        @load_paths = load_paths
        @cache          = {}
        @mtimes         = {}
        @files_loaded   = {}
        @loaded_classes = {}
      end

      def reset!
        cache.clear
        mtimes.clear
        files_loaded.clear
        loaded_classes.clear
      end

      def reload!
        rotation do |file, mtime|
          # Retrive the last modified time
          new_file = mtimes[file].nil?
          previous_mtime = mtimes[file] ||= mtime
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
          new_file = mtimes[file].nil?
          previous_mtime = mtimes[file] ||= mtime
          changed = true if new_file || mtime > previous_mtime
        end
        changed
      end
      alias :run! :changed?


      def dependency_file?(file)
        true
      end

      def classes_for_file(file)
        loaded_classes[file]
      end

      def file_for_class(klass)
        loaded_classes.select do |file, classes|
          classes.include?(klass)
        end.keys
      end
      ##
      # A safe Kernel::load which issues the necessary hooks depending on results
      #
      def safe_load(file, mtime=nil)
        reload = mtime && mtime > mtimes[file]

        logger.debug "Reloading #{file}" if reload

        # Removes all classes declared in the specified file
        if klasses = loaded_classes.delete(file)
          klasses.each { |klass| remove_constant(klass) }
        end

        # Keeps track of which constants were loaded and the files
        # that have been added so that the constants can be removed
        # and the files can be removed from $LOADED_FEAUTRES
        if self.files_loaded[file]
          self.files_loaded[file].each do |fl|
            next if fl == file
            $LOADED_FEATURES.delete(fl) if dependency_file?(fl)
          end
        end

        # Now reload the file ignoring any syntax errors
        $LOADED_FEATURES.delete(file)

        # Duplicate objects and loaded features in the file
        klasses = ObjectSpace.classes.dup
        already_loaded = $LOADED_FEATURES.dup

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
        if self.files_loaded[file]
          self.files_loaded[file].each do |fl|
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
          mtimes[file] = mtime if mtime
        end

        # Store the file details after successful loading
        loaded_classes[file] = ObjectSpace.classes - klasses
        self.files_loaded[file]   = $LOADED_FEATURES - already_loaded

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
        begin
          base = parts.size == 1 ? Object : Object.full_const_get(parts[0..-2].join("::"))
          object = parts[-1].to_s
          base.send(:remove_const, object)
        rescue NameError => e
          # logger.warn(e)
        end

        nil
      end

      ##
      # Searches Ruby files in your load_paths and monitors them for any changes.
      #
      def rotation
        paths = []

        files = load_paths.map do |glob|
          Dir[glob]
        end.flatten.uniq

        files.map { |file|
          found, stat = figure_path(file, paths)
          next unless found && stat && mtime = stat.mtime

          cache[file] = found

          yield(found, mtime)
        }.compact
      end

      ##
      # Takes a relative or absolute +file+ name and a couple possible +paths+ that
      # the +file+ might reside in. Returns the full path and File::Stat for that path.
      #
      def figure_path(file, paths)
        found = cache[file]
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
        cache.delete(file) and false
      end
    end

  end # Loader

  class SchemaLoader < Loader
    def reloader
      @reloader ||= SchemaReloader.new(load_paths)
    end
    class SchemaReloader < Loader::Reloader
      def schema_classes_for_file(file)
        if klasses = classes_for_file(file)
          klasses.select { |c| is_schema_class?(c) }
        else
          []
        end
      end

      # Because the schema classes are so tied up together reloading
      # must be done in the right order.
      # This method works by finding all the modified files then
      # mapping those to modified classes. Using the Schema, we find
      # all the subclasses affected by the modified file and map those
      # to files.
      # To reload these we must first reload the superclass, otherwise
      # the subclasses will re-load but load schema definitions from the
      # already loaded but out-of-date superclass and we'll end up
      # with orphaned box and field definitions
      def reload!
        changed_files = []
        rotation do |file, mtime|
          # Retrive the last modified time
          new_file = mtimes[file].nil?
          previous_mtime = mtimes[file] ||= mtime
          logger.debug "Detected a new file #{file}" if new_file
          # We skip to next file if it is not new and not modified
          changed_files << [file, mtime] if new_file || mtime > previous_mtime
          # Now we can reload our file
        end
        all_classes = schema.classes.dup

        modified_classes = changed_files.map do |file, mtime|
          schema_classes_for_file(file)
        end.flatten

        affected_subclasses = modified_classes.map do |modified_class|
          all_classes.select { |schema_class|
            schema_class < modified_class
          }
        end.flatten


        subclass_files_to_reload = affected_subclasses.map do |subclass|
          file_for_class(subclass)
        end.flatten

        changed_files.each { |file, mtime| safe_load(file, mtime) }
        subclass_files_to_reload.each { |file| safe_load(file) }
      end

      def schema
        Spontaneous.schema
      end

      def is_schema_class?(klass)
        (klass < Spontaneous::Page or klass < Spontaneous::Piece or klass < Spontaneous::Box)
      end

      def remove_constant(const)
        if is_schema_class?(const)
          super
        end
      end

      def dependency_file?(file)
        path = ::File.expand_path(file)
        tests = load_paths.map { |load_path| ::File.fnmatch?(load_path, path) }
        tests.any? { |t| t }
      end
    end
  end
end # Spontaneous

# encoding: UTF-8

require 'active_support/ordered_hash'

module Spontaneous
  OrderedHash = ActiveSupport::OrderedHash unless defined?(OrderedHash)

  module Loader
    class << self
      def load
        Spontaneous.load_paths.each do |component, path|
          root = \
            case path.first
            when Proc
              path.first.call
            else
              path.first
            end
          load_classes(root / path.last)
        end
      end

      def load_file(file)
        # logger.debug("-- Loaded #{File.basename(file, '.rb')}")
        require(file)
      end

      # thank you oh makers of Merb for your genius
      def load_classes(*paths)
        orphaned_classes = []
        paths.flatten.each do |path|
          Dir[path].sort.each do |file|
            begin
              load_file file
            rescue NameError => ne
              # puts "Stashed file with missing requirements for later reloading: #{file}"
              # ne.backtrace.each_with_index { |line, idx| puts "[#{idx}]: #{line}" }
              orphaned_classes.unshift(file)
            end
          end
        end
        load_classes_with_requirements(orphaned_classes)
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
  end # Loader
  class << self
    attr_accessor :load_paths

    def add_path(type, path, file_glob="**/*.rb")
      load_paths[type] = [path, file_glob]
    end

    unless Spontaneous.load_paths.is_a?(OrderedHash)
      Spontaneous.load_paths = OrderedHash.new
      Spontaneous.add_path(:schema, lambda { Spontaneous.schema_root })
      Spontaneous.add_path(:lib, lambda { Spontaneous.root / 'lib' })
    end
  end
end # Spontaneous


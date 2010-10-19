
module Spontaneous
  module Schema
    class << self
      def load(root=nil)
        schema_files = (root || Spontaneous.schema_root) / "**/*.rb"
        load_classes(schema_files)
      end

      def load_file(file)
        puts "-- Loaded #{file}" if require file
      end

      def load_classes(*paths)
        orphaned_classes = []
        paths.flatten.each do |path|
          Dir[path].sort.each do |file|
            begin
              load_file file
            rescue NameError => ne
              puts "Stashed file with missing requirements for later reloading: #{file}"
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
  end
end

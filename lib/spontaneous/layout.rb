# encoding: UTF-8

module Spontaneous
  class Layout < Style
    def try_paths
      [["layouts", prototype.name.to_s]]
    end

    class Default < Layout
      # If no named layouts have been defined first look for a layout
      # matching the class of our owner, then default to the 'standard'
      # layout.
      def try_paths
        named_layout = self.class.to_directory_name(owner)
        [["layouts", named_layout], ["layouts", "standard"]]
      end
    end

    class Anonymous
      def initialize(templates = {})
        @templates = templates
      end

      def template(format = :html)
        template = @templates[format]
        # a layout without a format is used as a fallback
        template ||= @templates[nil]
        template
      end

      def name
        nil
      end

      def schema_id
        nil
      end
    end
  end
end

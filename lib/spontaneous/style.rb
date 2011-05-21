# encoding: UTF-8


module Spontaneous
  class UnsupportedFormatException < Exception
    def initialize(style, unsupported_format)
      super("'#{unsupported_format}' format not supported by style '#{style.name}'.\nTemplate path: #{style.directory}\n")
    end
  end

  class Style
    attr_reader :directory, :name, :options

    def initialize(directory, name, options={})
      @directory, @name, @options = directory, name.to_sym, options
    end

    def style_id
      name
    end

    def template(format = :html)
      try_templates.detect do |t|
        Spontaneous::Render.exists?(t, format)
      end.tap do |t|
        logger.error("Missing templates: #{try_templates.join(',')}") if t.nil?
      end
    end

    def try_templates
      [::File.join([directory, name.to_s].compact), name.to_s].uniq
    end

    alias_method :path, :template

    def default?
      @options[:default]
    end

    def exists?(format = :html)
      S::Render.exists?(template, format)
    end

    def formats
      Spontaneous::Render.formats(self)
    end

    class Anonymous
      def initialize(template_code = "")
        @template_code = template_code
      end
      def template(format = :html)
        Proc.new { @template_code }
      end
      def exists?(format = :html)
        true
      end

      def name
        nil
      end

      def style_id
        nil
      end
    end

    class BoxStyle < Style
      def initialize(owner_directory, type_directory, name, options={})
        @owner_directory, @type_directory, @name, @options = owner_directory, type_directory, name.to_sym, options
      end
      def try_templates
        [::File.join([directory, name.to_s].compact), name.to_s].uniq
      end
    end
  end


end

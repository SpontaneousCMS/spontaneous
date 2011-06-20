# encoding: UTF-8


module Spontaneous
  class UnsupportedFormatException < Exception
    def initialize(style, unsupported_format)
      super("'#{unsupported_format}' format not supported by style '#{style.name}'.\nTemplate path: #{style.directory}\n")
    end
  end

  class Style
    attr_reader :owner, :directory, :name, :options

    def initialize(owner, directory, name, options={})
      @owner, @directory, @name, @options = owner, directory, name.to_sym, options
    end

    def schema_name
      "style/#{owner.schema_id}/#{name}"
    end

    def schema_owner
      owner
    end

    # TODO: new style class that has a better way of knowing if it's anonymous
    # or named. Only named styles have schema_ids -- anonymous styles are resolved
    # according to the files on the disk
    def schema_id
      @options[:style_id] ? Spontaneous::Schema.schema_id(self) : nil
    end


    def template(format = :html)
      try_templates.detect do |t|
        Spontaneous::Render.exists?(t, format)
      end.tap do |t|
        # logger.error("Missing templates: #{try_templates.join(',')}") if t.nil?
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

    def to_hash
      {
        :name => name.to_s,
        :schema_id => schema_id.to_s
      }
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

      def schema_id
        nil
      end
    end
  end
end


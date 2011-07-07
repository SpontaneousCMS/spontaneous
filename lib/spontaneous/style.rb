# encoding: UTF-8


module Spontaneous
  class Style
    def self.to_directory_name(klass)
      return nil if klass.name.blank?
      klass.name.demodulize.underscore
    end

    attr_reader :owner, :prototype

    def initialize(owner, prototype = nil)
      @owner, @prototype = owner, prototype
    end

    def schema_id
      self.prototype.schema_id
    end

    def template(format = :html)
      unless template = inline_template(format)
        unless template = local_template(format)
          template = supertype_template(format)
        end
      end
      unless template
        logger.warn("No template file found for style #{owner}/#{name}.#{format}")
        template = anonymous_template
      end
      template
    end

    alias_method :path, :template

    def supertype_template(format)
      supertype = owner.supertype
      if supertype && supertype != Spontaneous::Content
        self.class.new(supertype, prototype).template(format)
      else
        nil
      end
    end

    def anonymous_template
      Proc.new { "" }
    end

    def name
      prototype.name
    end

    def inline_template(format)
      if template_string = owner.inline_templates[format.to_sym]
        Anonymous.new(template_string).template(format)
      end
    end

    def local_template(format)
      try_template_paths.detect do |t|
        Spontaneous::Render.exists?(t, format)
      end
    end

    def try_template_paths
      try_templates.map { |path| Array === path ? File.join(path.compact) : path }.uniq
    end

    def try_templates
      name = prototype.name.to_s
      [[owner_directory_name, name], name]
    end

    def owner_directory_name
      self.class.to_directory_name(owner)
    end


    def default?
      @options[:default]
    end

    # def exists?(format = :html)
    #   S::Render.exists?(template, format)
    # end

    def formats
      Spontaneous::Render.formats(self)
    end

    # def to_hash
    #   {
    #     :name => name.to_s,
    #     :schema_id => schema_id.to_s
    #   }
    # end

    def ==(other)
      other.class == self.class && other.prototype == self.prototype && other.owner == self.owner
    end

    class Default < Style
      def name
        "<default>"
      end

      def schema_id
        nil
      end

      def try_templates
        [owner_directory_name]
      end
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

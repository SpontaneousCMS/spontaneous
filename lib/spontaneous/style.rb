# encoding: UTF-8


module Spontaneous
  class Style
    attr_reader :owner, :prototype

    def initialize(owner, prototype = nil)
      @owner, @prototype = owner, prototype
    end

    def schema_id
      self.prototype.schema_id
    end

    def template(format = :html, renderer = nil)
      renderer ||= Spontaneous::Output.default_renderer(format, @owner.site)
      inline_template(format) || external_template(format, renderer)
    end

    def external_template(format = :html, renderer)
      unless (template = (file_template(format, renderer) || supertype_template(format, renderer)))
        logger.warn("No template file found for style #{owner}:#{name}.#{format}")
        template = anonymous_template
      end
      template
    end

    def file_template(format, renderer)
      local_template(format, renderer)
    end

    # Tests to see if a template file exists for the specified format.
    # If one doesn't exist then the style would fall back to an
    # 'anonymous' template.
    def template?(format = :html, renderer = nil)
      # renderer ||= renderer_for_format(format)
      !(inline_template(format) || file_template(format, renderer)).nil?
    end

    alias_method :path, :template

    def local_template(format, renderer)
      try_template_paths.map { |path|
        renderer.template_location(path, format)
      }.detect { |path| !path.nil? }
    end

    def supertype_template(format, renderer)
      template = try_supertype_styles(renderer).each { |style|
        template = style.template(format, renderer)
        return template unless template.nil?
      }
      nil
    end

    def try_supertype_styles(renderer)
      class_ancestors(owner).take_while { |a| a and a < owner.model }.
        map { |s| supertype_style_class.new(s, prototype) }
    end

    def supertype_style_class
      self.class
    end

    def class_ancestors(klass)
      ancestors = []
      obj = klass
      while obj
        obj = obj.supertype
        ancestors << obj if obj
      end
      ancestors
    end

    def inline_template(format)
      if (template_string = owner.inline_templates[format.to_sym])
        Anonymous.new(template_string).template(format)
      end
    end

    def anonymous_template
      Proc.new { "" }
    end

    def name
      return "<default>" if prototype.nil?
      prototype.name
    end

    def try_template_paths
      try_paths.map { |path| Array === path ? File.join(path.compact) : path }.uniq
    end

    def try_paths
      name = prototype.name.to_s
      owner_directory_paths(name).push(name)
    end

    def owner_directory_names
      classes = [owner].concat(owner.ancestors.take_while { |klass| klass < owner.model::Page or klass < owner.model::Piece })
      classes.map { |klass| to_directory_name(klass) }
    end

    def to_directory_name(klass)
      return nil if klass.name.blank?
      klass.name.demodulize.underscore
    end

    def owner_directory_paths(basename)
      owner_directory_names.map { |dir| [dir, basename] }
    end

    def default?
      @options[:default]
    end

    def formats
      Spontaneous::Render.formats(self)
    end

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

      def try_paths
        owner_directory_names
      end
    end

    class Anonymous
      def initialize(template_code = "")
        @template_code = template_code
      end

      def template(format = :html, renderer = nil)
        Proc.new { @template_code }
      end

      def name
        nil
      end

      def schema_id
        nil
      end
    end

    # Aliases are unique in that their style depends on the instance as well
    # as the class.
    # This style searches for appropriate templates based on the class of the
    # instance before falling back to templates for the target.
    class AliasStyle
      def initialize(instance)
        @instance = instance
      end

      def template(format = :html, renderer = nil)
        renderer ||= @instance.page.output(format).default_renderer
        target_is_content = @instance.target.respond_to?(:resolve_style)
        if (style = @instance.resolve_style(@instance.style_sid))
          return style.template(format, renderer) if !target_is_content || style.template?(format, renderer)
        end
        style = @instance.target.resolve_style(@instance.style_sid)
        style.template(format, renderer)
      end
    end
  end
end

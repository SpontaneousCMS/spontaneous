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
        template = find_template(format)
      end
      template
    end

    def find_template(format = :html)
      unless template = local_template(format)
        template = supertype_template(format)
      end
      unless template
        logger.warn("No template file found for style #{owner}/#{name}.#{format}")
        template = anonymous_template
      end
      template
    end

    alias_method :path, :template

    def local_template(format)
      template_path = nil
      Spontaneous.template_paths.each do |template_root|
        template_path = try_template_paths.detect do |path|
          Spontaneous::Render.exists?(template_root, path, format)
        end
        return (template_root / template_path) if template_path
      end
      nil
    end

    def supertype_template(format)
      supertype = owner.supertype
      if supertype && supertype != Spontaneous::Content
        self.class.new(supertype, prototype).template(format)
      else
        nil
      end
    end

    def inline_template(format)
      if template_string = owner.inline_templates[format.to_sym]
        Anonymous.new(template_string).template(format)
      end
    end

    def anonymous_template
      Proc.new { "" }
    end

    def name
      prototype.name
    end

    def try_template_paths
      try_paths.map { |path| Array === path ? File.join(path.compact) : path }.uniq
    end

    def try_paths
      name = prototype.name.to_s
      # [[owner_directory_name, name], name]
      # owner_directory_names.map { |dir| [dir, name] }.push(name)
      owner_directory_paths(name).push(name)
    end

    def owner_directory_names
      classes = [owner].concat(owner.ancestors.take_while { |klass| klass < Spontaneous::Page or klass < Spontaneous::Piece })
      classes.map { |klass| self.class.to_directory_name(klass) }
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

    # def export
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

      def try_paths
        owner_directory_names
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

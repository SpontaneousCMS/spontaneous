# encoding: UTF-8


module Spontaneous
  class UnsupportedFormatException < Exception
    def initialize(style, unsupported_format)
      super("'#{unsupported_format}' format not supported by style '#{style.name}'.\nTemplate path: #{style.directory}\n")
    end
  end

  class Style
    def initialize(owner, name, options={})
      @owner = owner
      @name = name.to_sym
      @options = options
    end

    def name
      @name
    end

    def owner
      @owner
    end

    def title
      @options[:title] || default_title
    end

    def default_title
      @name.to_s.titleize
    end

    def default?
      @options[:default]
    end

    def directory
      owner_directory_name
    end

    def owner_directory_name
      if class_name = @options[:class_name]
        class_name.underscore
      else
        if @owner.respond_to?(:style_directory_name)
          @owner.style_directory_name
        else
          @owner.name.demodulize.underscore
        end
      end
    end

    def filename(format=:html)
      "#{basename}.#{format}.#{Spontaneous.template_ext}"
    end

    def basename
      @options[:filename] || name
    end

    def path(format=:html)
      File.join(directory, basename.to_s)
    end

    def formats
      Spontaneous::Render.formats(self)
    end

    def template(format=:html)
      format = format.to_sym
      # raise UnsupportedFormatException.new(self, format) unless formats.include?(format)
      # template_cache[format]
      # Render.engine.get_template(basename, format)
      path(format)
    end

    def template_cache
      @template_cache ||= Hash.new do |hash, format|
        hash[format] = Templates::ErubisTemplate.new(path(format))
      end
    end
  end
end

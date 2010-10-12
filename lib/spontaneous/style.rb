
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
      File.join(Spontaneous.template_root, owner_directory_name)
    end

    def owner_directory_name
      @owner.class.name.underscore
    end

    def filename(format=:html)
      "#{basename}.#{format}.#{Spontaneous.template_ext}"
    end

    def basename
      @options[:filename] || name
    end

    def path(format=:html)
      File.join(directory, filename(format))
    end

    def formats
      @formats ||= \
        begin
        path = Pathname.new(directory)
        matcher = %r(^#{name}\.(\w+).#{Spontaneous.template_ext}$)
        path.children(false).select do |file|
          file.to_s =~ matcher
        end.map do |file|
          matcher.match(file.to_s)[1].to_sym
        end
      end
    end

    def template(format=:html)
      format = format.to_sym
      raise UnsupportedFormatException.new(self, format) unless formats.include?(format)
      template_cache[format]
    end

    def template_cache
      @template_cache ||= Hash.new do |hash, format|
        hash[format] = Template.new(path(format))
      end
    end
  end
end

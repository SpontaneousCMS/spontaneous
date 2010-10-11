
module Spontaneous
  class Template
    def initialize(owner, name)
      @owner = owner
      @name = name
    end

    def name
      @name
    end


    def directory
      File.join(Spontaneous.template_root, owner_directory_name)
    end

    def owner_directory_name
      @owner.class.name.underscore
    end

    def filename(format=:html)
      "#{name}.#{format}.#{Spontaneous.template_ext}"
    end

    def path(format=:html)
      File.join(directory, filename(format))
    end

    def formats
      path = Pathname.new(directory)
      matcher = %r(^#{name}\.(\w+).#{Spontaneous.template_ext}$)
      path.children(false).select do |file|
        file.to_s =~ matcher
      end.map do |file|
        matcher.match(file.to_s)[1].to_sym
      end
    end
  end
end

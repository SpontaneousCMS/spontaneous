# encoding: UTF-8

module Cutaneous
  class Renderer# < Spontaneous::Renderer
    attr_reader :template_root, :cache_root

    def initialize(template_root, cache = nil)
      @template_root = template_root
      @cache = cache
    end

    def use_cache?
      @cache
    end

    def extension
      Cutaneous.extension
    end

    def render_string(string, content, format = :html, params = {})
      template = string_to_template(string)
      render_template(template, content, format, params)
    end

    def render_file(file_path, content, format = :html, params = {})
      template = get_template(file_path, format)
      render_template(template, content, format, params)
    end

    def render(filename, context, _layout=true)
      hook_context(context)
      while true
        template = get_template(filename, context.format)
        _buf = context._buf
        output = template.render(context)
        context._buf = _buf
        unless context._layout.nil?
          layout = context._layout
          context._layout = nil
        end
        break unless layout
        filename = layout
        layout = false
      end
      output
    end

    protected

    def render_template(template, content, format, params = {})
      context = context_class.new(content, format, params)
      render(template, context)
    end


    def create_template(filepath, format)
      template = template_class.new(nil, format)
      case filepath
      when String
        template.timestamp = Time.now
        template.filename = filepath
        if use_cache?
          cache_path = filepath[0...(-Cutaneous.extension.length)] + 'rb'
          if test(?f, cache_path)
            # puts "Using cached template #{cache_path}"
            template.filename = cache_path
            template.script = File.read(cache_path)
          else
            template.convert(File.read(filepath), filepath)
            File.open(cache_path, 'w') do |f|
              f.flock(File::LOCK_EX)
              f.write(template.script)
            end
          end
        else
          template.convert(File.read(filepath), filepath)
        end
      when Proc
        template = template_class.new(nil, format)
        template.convert(filepath.call, filepath.to_s)
      end
      template
    end

    def get_template(template, format)
      case template
      when String
        # if the path is absolute and points to an existing file, just render that
        # used by the published renderer
        filepath = make_path_absolute(template, format)
        create_template(filepath, format)
      when Proc
        create_template(template, format)
      else
        template
      end
    end

    def make_path_absolute(path, format)
      if ::File.file?(path)
        path
      else
        Spontaneous::Render.find_template(path, format)
      end
    end

    def string_to_template(string)
      template = template_class.new
      template.convert(string)
      template
    end


    def hook_context(context)
      context._engine = self
      context._layout = nil
      context
    end
  end
end




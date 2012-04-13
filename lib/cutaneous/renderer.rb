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

    def render_string(string, context)
      template = string_to_template(string)
      render_template(template, context)
    end

    def render_file(file_path, context)
      template = get_template(file_path, context)
      render_template(template, context)
    end

    def render(filename, context, _layout=true)
      hook_context(context)
      while true
        template = get_template(filename, context)
        _buf = context._buf
        output = template.render(context)
        context._buf = _buf
        unless context._layout.nil?
          layout = context._layout
          # context._clean!
          context._layout = nil
        end
        break unless layout
        filename = layout
        layout = false
      end
      output
    end

    # Private: Provides a list of modules that should be
    # included into the context class after the format specific
    # extensions have been included.
    #
    # Some contexts need to override the default behaviour of the
    # base Spontaneous context so we need to be able to append modules
    # to the end of the format specific ones in order to maintain this
    # ability.
    def context_extensions
      []
    end

    protected

    def render_template(template, context)
      # context = context_class.new(content, format, params)
      render(template, context)
    end


    def create_template(filepath)
      template = template_class.new(nil)
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
        template = template_class.new(nil)
        template.convert(filepath.call, filepath.to_s)
      end
      template
    end

    def get_template(template, context)
      case template
      when String
        # if the path is absolute and points to an existing file, just render that
        # used by the published renderer
        filepath = make_path_absolute(template, context)
        create_template(filepath)
      when Proc
        create_template(template)
      else
        template
      end
    end

    def make_path_absolute(path, context)
      if ::File.file?(path)
        path
      else
        Spontaneous::Render.find_template(path, context.format)
      end
    end

    def string_to_template(string)
      template = template_class.new
      template.convert(string)
      template
    end


    def hook_context(context)
      unless context.nil?
        context._engine = self
        context._layout = nil
      end
    end
  end
end


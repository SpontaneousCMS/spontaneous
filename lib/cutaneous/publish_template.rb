# encoding: UTF-8

module Cutaneous
  class PublishTemplate
    attr_reader   :parser
    attr_writer   :script
    attr_accessor :timestamp, :filename

    def initialize(template_file = nil, format=:html)
      @format = format
      convert_file(template_file) if template_file
    end

    def convert_file(template_file)
      convert(File.read(template_file), template_file)
    end

    def convert(template_string, filepath = nil)
      @template_proc = @script = nil
      @filename = filepath
      @parser = create_parser(template_string)
      script
    end

    def script
      return nil unless @parser or @script
      @script ||= @parser.script
    end

    # I'm not doing any type checking here as I know exactly where the calls are coming from
    def render(context)
      begin
        context.instance_eval(&template_proc)
      rescue => e
        if context.show_errors?
          raise e
        else
          logger.warn(e)
          ""
        end
      end
    end

    protected

    def template_proc
      @template_proc ||= eval(template_proc_src.untaint, nil, @filename || '(cutaneous)')
    end

    def template_proc_src
      "lambda { |context| self._buf = _buf = ''; #{script}; _buf.to_s }"
    end

    def create_parser(template_string)
      parser_class.new(template_string)
    end

    def parser_class
      Cutaneous::PublishTokenParser
    end
  end
end

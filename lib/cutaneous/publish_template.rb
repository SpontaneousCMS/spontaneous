# encoding: UTF-8

module Cutaneous
  class PublishTemplate
    attr_reader :filename, :parser

    def initialize(template_file = nil)
      convert_file(template_file) if template_file
    end

    def convert_file(template_file)
      convert(File.read(template_file), template_file)
    end

    def convert(template_string, filepath = nil)
      @template_proc = nil
      @filename = filepath
      @parser = create_parser(template_string)
      script
    end

    def script
      return nil unless @parser
      @parser.script
    end

    # I'm not doing any type checking here as I know exactly where the calls are coming from
    def render(context)
      context.instance_eval(&template_proc)
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

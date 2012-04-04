# encoding: UTF-8

require 'rack'

module Spontaneous::Plugins::Page
  module Formats
    extend ActiveSupport::Concern

    module ClassMethods
      def format_for(format_name)
        Spontaneous::Render::Output.new(format_name)
      end

      def outputs(*outputs)
        return output_list if outputs.nil? or outputs.empty?
        set_outputs(outputs)
      end

      def output_list
        @outputs ||= supertype_outputs
      end

      def add_output(format, *args)
        options = args.extract_options!
        output = define_output(format, options)
        if (index = output_list.index { |o| o == output })
          output_list[index] = output
        else
          output_list.push(output)
        end
      end

      def set_outputs(outputs)
        outputs = outputs.flatten
        output_list.clear
        outputs.map do |format|
          output_list.push define_output(format)
        end
      end

      def define_output(format, options = {})
        Spontaneous::Render::Output.new(format, options).tap do |f|
          raise Spontaneous::UnknownFormatException.new(format) unless f.mime_type
        end
      end

      def supertype_outputs
        supertype? && supertype.respond_to?(:outputs) ? supertype.outputs.dup : [standard_output]
      end

      def standard_output
        Spontaneous::Render::Output.new(:html)
      end

      def default_output
        outputs.first
      end

      def provides_format?(format)
        format = (format || :html).to_sym
        outputs.include?(format)
      end

      alias_method :provides_output?, :provides_format?

      def output(format_name = nil)
        return format_name if format_name.is_a?(Spontaneous::Render::Output)
        return default_output if format_name.blank?
        output_list.detect { |o| o == format_name } || Spontaneous::Render::Output.new(format_name)
      end

      def mime_type(format)
        return format.mime_type if format.respond_to?(:mime_type)
        if (match = output(format))
          match.mime_type
        else
          ::Rack::Mime.mime_type(".#{format}")
        end
      end
    end # ClassMethods

    def outputs
      self.class.outputs
    end

    def default_output
      self.class.default_output
    end

    def provides_format?(format)
      self.class.provides_format?(format)
    end

    def output(format)
      self.class.output(format)
    end

    def mime_type(format)
      self.class.mime_type(format)
    end
  end # Formats
end # Spontaneous::Plugins::Page

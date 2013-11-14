# encoding: UTF-8

require 'rack'

module Spontaneous::Model::Page
  module Formats
    extend Spontaneous::Concern

    module ClassMethods
      def outputs(*outputs)
        return output_list if outputs.nil? or outputs.empty?
        set_outputs(outputs)
      end

      def output_map
        @outputs ||= supertype_outputs
      end

      def output_list
        output_map.values
      end

      def add_output(format, *args)
        options = args.extract_options!
        output = define_and_add_output(format, options)
      end

      def set_outputs(outputs)
        output_map.clear
        outputs.each do |definition|
          define_and_add_output(*definition)
        end
      end

      def define_and_add_output(format, options = {})
        output = define_output(format, options)
        output_map[output.name] = output
      end

      def define_output(format, options = {})
        o = Spontaneous::Output.create(format, options).tap do |output|
          silence_warnings { self.const_set("Output#{format.to_s.upcase}", output) }
        end
      end

      def supertype_outputs
        supertype? && supertype.respond_to?(:outputs) ? supertype.output_map.dup : { :html => standard_output }
      end

      def standard_output
        define_output(:html)
      end

      def default_output
        output_list.first
      end

      def provides_format?(format)
        return true if format.blank?
        format = format.to_s
        outputs.any? { |output| (output == format) or (output.name.to_s == format) }
      end

      alias_method :provides_output?, :provides_format?

      def output(name = nil)
        output_without_validation(name) or raise Spontaneous::UnknownOutputException.new(self, name)
      end

      def output_without_validation(name = nil)
        return name if name.is_a?(Spontaneous::Output::Format)
        return default_output if name.blank?
        output_map[name.to_sym]
      end

      def mime_type(format)
        return format.mime_type if format.respond_to?(:mime_type)
        if (match = output_without_validation(format))
          match.mime_type
        else
          ::Rack::Mime.mime_type(".#{format}")
        end
      end
    end # ClassMethods

    def outputs
      self.class.outputs.map { |output| output.new(self) }
    end

    def default_output
      self.class.default_output.new(self)
    end

    def provides_output?(format)
      self.class.provides_output?(format)
    end

    def output(format, content = nil)
      return format if format.is_a?(Spontaneous::Output::Format)
      output_class = self.class.output(format)
      output_class.new(self, content)
    end

    def mime_type(format)
      self.class.mime_type(format)
    end

    def render(format = :html, locals = {}, parent_context = nil)
      locals, format = format, :html if format.is_a?(Hash)
      output = output(format)
      output.render(locals, parent_context)
    end
  end # Formats
end # Spontaneous::Plugins::Page

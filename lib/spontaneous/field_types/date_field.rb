# encoding: UTF-8

module Spontaneous
  module FieldTypes
    class DateField < Field
      include Spontaneous::Plugins::Field::EditorClass

      DEFAULT_FORMAT = "%A, %-d %B, %Y"

      def self.export(user)
        super.merge({
          :date_format => prototype.options[:format] || DEFAULT_FORMAT
        })
      end

      def value(output = :html, *args)
        return date if date.is_a?(String)
        case output
        when :html
          date.strftime(html_format)
        else
          date.strftime(format)
        end
      end

      def outputs
        [:julian]
      end

      def preprocess(value)
        return value if value.blank?
        Date.parse(value)
      end

      def html_format
        %(<time datetime="%Y-%m-%d">#{ format }</time>)
      end

      def generate_julian(date)
        return date.jd if date.is_a?(Date)
        date.to_s
      end

      def date
        return "" if values[:julian].blank?
        Date.jd values[:julian].to_i
      end

      def format
        prototype.options[:format] ||  DEFAULT_FORMAT
      end
    end

    DateField.register
  end
end

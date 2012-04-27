# encoding: UTF-8

module Spontaneous::FieldTypes
  # Provides a select field in the UI.
  #
  # Options for the select are provided by passing an :options value in the field config.
  #
  # This form gives a fixed list of options:
  #
  # class Something < Piece
  #   field :choices, :select, :options => [ ["value1", "Label 1"], ["value2", "Label 2"] ]
  # end
  #
  #
  # But you can provide a dynamic set by passing a Proc as the value of
  # the :options parameter:
  #
  #   field :choices, :select, :options => proc { |page, box|
  #     Things.all.map { |thing| [thing.id, thing.name] }
  #   }
  #
  # In this case the options list will be generated dynamically every time the field is edited.
  #
  # To retrieve the selected value, use the standard field.value form. In the case of the
  # example above, the field would return either "value1" or "value2".
  #
  # To retrieve the associated label use field.value(:label) or field.label
  #
  class SelectField < Field
    include Spontaneous::Plugins::Field::EditorClass

    def self.static_option_list?
      return false if configured_option_list.is_a?(Proc)
      true
    end

    def self.configured_option_list
      prototype.options[:options]
    end

    def self.export(user)
      default_value = super
      return default_value unless static_option_list?
      default_value.merge({
        :option_list => configured_option_list
      })
    end

    def option_list(content, box)
      case (opts = configured_option_list)
      when Proc
        opts.call(content, box)
      when Array
        opts
      else
        []
      end
    end

    def configured_option_list
      prototype.options[:options]
    end

    def outputs
      [:html, :label]
    end

    def generate(output, value)
      return "" if value.blank?
      value[[:html, :label].index(output)]
    end

    def preprocess(value)
      Spontaneous::JSON.parse(value)
    end

    def label
      value(:label)
    end

    def ui_preview_value
      unprocessed_value
    end

    self.register
  end # OptionsField
end


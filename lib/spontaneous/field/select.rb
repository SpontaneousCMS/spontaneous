# encoding: UTF-8

module Spontaneous::Field
  # Provides a select field in the UI.
  #
  # Options for the select are provided by passing an :options value in the field config.
  #
  # This form gives a fixed list of options whose values & labels are the same:
  #
  #   class Something < Piece
  #     field :choices, :select, :options => [ "First Option", "Second Option" ]
  #   end
  #
  # This will generate a select tag showing "First Option" and "Second Option" in the
  # editing UI.
  #
  # If you want to have the generated <option/> tag values to be different from the label,
  # then pass an array of arrays as the options:
  #
  #   class Something < Piece
  #     field :choices, :select, :options => [ ["value1", "Label 1"], ["value2", "Label 2"] ]
  #   end
  #
  # You can provide a dynamic set by passing a Proc as the value of the :options parameter:
  #
  #   field :choices, :select, :options => proc { |page, box|
  #     Things.all.map { |thing| [thing.id, thing.name] }
  #   }
  #
  # In this case the options list will be generated dynamically every time the field is edited.
  #
  # To retrieve the selected value from the field, use the standard field.value form.
  # In the case of the example above, the field would return either "value1" or "value2".
  #
  # To retrieve the associated label use `field.value(:label)` or `field.label`
  # ("Value 1" or "Value 2" in the exampel above).
  #
  class Select < Base
    has_editor

    def self.static_option_list?
      return false if configured_option_list.is_a?(Proc)
      true
    end

    def self.configured_option_list
      @configured_option_list ||= normalize_options_list(prototype.options[:options])
    end

    def self.normalize_options_list(options)
      return options if options.is_a?(Proc)
      options.map { |opt|
        case opt
        when Array
          opt
        else
          [opt, opt]
        end.map { |opt| opt.to_s }
      }
    end

    def self.export(user)
      default_value = super
      return default_value unless static_option_list?
      default_value.merge({
        :option_list => configured_option_list
      })
    end

    def self.option_list(owner)
      case (opts = configured_option_list)
      when Proc
        opts.call(owner)
      when Array
        opts
      else
        []
      end
    end

    # Maps a configured default value to the appropriate JSON encoded [value, label] array
    def self.make_default_value(instance, value)
      return nil if value.blank?
      option = option_list(instance.owner).detect { |opt, label| opt == value }
      return nil if option.nil?
      Spontaneous::JSON.encode option
    end

    def option_list
      self.class.option_list(self.owner)
    end

    def outputs
      [:html, :label]
    end

    def generate(output, value, site)
      return "" if value.blank?
      value[[:html, :label].index(output)]
    end

    def preprocess(value, site)
      Spontaneous::JSON.parse(value)
    end

    def label
      value(:label)
    end

    def ui_preview_value
      unprocessed_value
    end

    self.register
  end # Select
end

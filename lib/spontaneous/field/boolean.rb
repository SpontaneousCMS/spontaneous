# encoding: UTF-8

module Spontaneous::Field
  class Boolean < Base
    has_editor "Spontaneous.Field.Boolean"

    def self.default_options
      {default: true, true: "Yes", false: "No"}
    end

    def self.export(user)
      super.merge({
        labels: { true: prototype.options[:true], false: prototype.options[:false] }
      })
    end

    def outputs
      [:boolean, :html, :string]
    end

    def value(format = :boolean)
      super(format)
    end

    def checked?
      value(:boolean)
    end

    alias_method :on?, :checked?
    alias_method :enabled?, :checked?

    def preprocess(value, site)
      case value
      when TrueClass, FalseClass
        value
      when "", nil
        o = self.class.prototype.options
        return o[:default] if o.key?(:default)
        true
      when "1", "true"
        true
      else
        false
      end
    end

    def generate_boolean(state, site)
      state
    end

    def generate_html(state, site)
      string_value(state)
    end

    def generate_string(state, site)
      string_value(state)
    end

    def string_value(state)
      self.class.prototype.options[(state ? :true : :false)]
    end

    self.register(:boolean, :switch)
  end
end

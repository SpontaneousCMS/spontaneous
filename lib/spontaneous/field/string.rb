# encoding: UTF-8

module Spontaneous::Field
  class String < Base
    has_editor

    def preprocess(value, site)
      Spontaneous::Utils::SmartQuotes.smarten(value.to_s)
    end

    def generate_html(value, site)
      escape_html(value)
    end

    self.register :string, :title
  end
end

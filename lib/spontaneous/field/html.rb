# encoding: UTF-8

module Spontaneous::Field
  class HTML < LongString

    # Just pass through the value without any kind of escaping
    def generate_html(value)
      value
    end

    self.register
  end
end

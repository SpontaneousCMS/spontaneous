# encoding: UTF-8

module Spontaneous
  module Generators
    autoload :Site, "spontaneous/generators/site"
    def self.available
      self.constants.map { |c| self.const_get(c) }.select do |c|
        c.ancestors.include?(Thor::Group)
      end
    end
  end # Generators
end # Spontaneous

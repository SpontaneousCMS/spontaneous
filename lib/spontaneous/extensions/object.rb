# encoding: UTF-8


module Spontaneous
  module Extensions
    module Object
      def blank?
        respond_to?(:empty?) ? empty? : !self
      end

      def full_const_get(name)
        list = name.split("::")
        list.shift if list.first.blank?
        obj = self
        list.each do |x|
          # This is required because const_get tries to look for constants in the
          # ancestor chain, but we only want constants that are HERE
          obj = obj.const_defined?(x) ? obj.const_get(x) : obj.const_missing(x)
        end
        obj
      end unless method_defined?(:full_const_get)
    end
  end
end


class Object
  include Spontaneous::Extensions::Object
end


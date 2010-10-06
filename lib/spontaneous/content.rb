
module Spontaneous
  class Content < Sequel::Model(:content)
    class << self
      alias_method :class_name, :name

      def name(custom_name=nil)
        self.name = custom_name if custom_name
        @name or default_name
      end

      def default_name
        n = class_name.split(/::/).last.gsub(/([A-Z]+)([A-Z][a-z])/,'\1 \2')
        n.gsub!(/([a-z\d])([A-Z])/,'\1 \2')
        n
      end

      def name=(name)
        @name = name
      end
    end
  end
end

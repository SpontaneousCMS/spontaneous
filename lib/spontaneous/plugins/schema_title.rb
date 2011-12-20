# encoding: UTF-8

module Spontaneous::Plugins
  module SchemaTitle
    extend ActiveSupport::Concern

    module ClassMethods
      def class_name_with_fallback
        n = name
        if n.nil? or n.empty?
          n = "ContentClass#{object_id}"
        end
        n
      end

      def title(custom_title=nil)
        self.title = custom_title if custom_title
        @title or default_title
      end

      def default_title
        n = class_name_with_fallback.split(/::/).last.gsub(/([A-Z]+)([A-Z][a-z])/,'\1 \2')
        n.gsub!(/([a-z\d])([A-Z])/,'\1 \2')
        n
      end

      def title=(title)
        @title = title
      end
    end # ClassMethods
  end # SchemaTitle
end

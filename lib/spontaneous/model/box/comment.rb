# encoding: UTF-8

require 'kramdown'

module Spontaneous::Model::Box
  module Comment
    extend Spontaneous::Concern

    module ClassMethods
      def comment(comment_text)
        @comment ||= comment_text
      end

      def schema_comment
        begin
          ::Kramdown::Document.new(unindented_comment).to_html.strip
        rescue => e
          puts "Error converting schema comment for #{self.class}:\n#{e}"
          ''
        end
      end

      def unindented_comment
        unindent(@comment)
      end

      def unindent(comment)
        return '' if comment.nil?
        indent = comment.match(/\A([\ \t]*)\S/) { |m| m[1] }
        return comment if indent.nil?
        comment.gsub(/^#{Regexp.escape(indent)}/, '')
      end
    end
  end
end

# encoding: UTF-8

module Spontaneous
  module Errors
    class Error < StandardError; end

    # raised when trying to show something that is not showable due to
    # ancestor being hidden
    class NotShowable < Error
      def initialize(content, hidden_ancestor_id)
        @content, @hidden_ancestor_id = content, hidden_ancestor_id
      end
    end
  end
end

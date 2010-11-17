module Cutaneous
  module PreviewContextHelper
    include ContextHelper

    def include(filename)
      _comment(filename)
      import(filename)
    end

    def _comment(text)
      @_comment_method ||= "_comment_#{format}".to_sym
      if (respond_to?(@_comment_method))
        @_buf << self.send(@_comment_method, text) if @_buf
      end
    end

    def _comment_html(text)
      "<!-- #{escape(text)} -->\n"
    end
  end
end

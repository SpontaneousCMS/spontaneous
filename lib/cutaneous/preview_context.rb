# encoding: UTF-8

module Cutaneous
  class PreviewContext
    include ContextHelper

    def include(filename)
      _comment(filename)
      import(filename)
    end

    def _decode_params(param, *args)
      if param.respond_to?(:start_inline_edit_marker)
        _comment(param.start_inline_edit_marker) << super << _comment(param.end_inline_edit_marker)
      else
        super
      end
    end

    def _comment(text)
      @_comment_method ||= "_comment_#{_format}".to_sym
      if (respond_to?(@_comment_method))
        self.send(@_comment_method, text)
      end
    end

    def _comment_html(text)
      "<!-- #{escape(text.to_s.escape_html)} -->\n"
    end
  end
end

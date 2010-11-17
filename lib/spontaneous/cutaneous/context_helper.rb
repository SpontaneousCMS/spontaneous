
module Spontaneous::Cutaneous
  module ContextHelper
    include Tenjin::ContextHelper
    ## over-ride this in implementations
    #
    def initialize(format=:html)
      @format = format
    end

    attr_reader :format

    def extends(parent)
      self._layout = parent
    end

    def block(block_name)
      @_block_positions ||= {}
      @_block_content ||= {}
      @_block_level ||= []
      block_name = block_name.to_sym
      @_block_positions[block_name] = self._buf.length
      @_block_level << block_name
      if block_given?
        yield
        output = endblock
      end
    end

    # the _block_name param is ignored though could throw warning if the two are different
    def endblock(_block_name=nil)
      block_name = @_block_level.pop
      return unless block_name
      start_position = @_block_positions[block_name]
      output = @_buf[start_position..-1]
      @_buf[start_position..-1] = ''
      if @_block_content.key?(block_name)
        @_buf << @_block_content[block_name]
      else
        if _layout.nil?
          @_buf << output
        else
          @_block_content[block_name] = output
        end
      end
      output
    end

    def include(filename)
      import(filename)
    end

    protected

    def _decode_params(param)
      unless param.is_a?(String)
        @_render_method ||= "to_#{format}".to_sym
        if param.respond_to?(@_render_method)
          param = param.send(@_render_method)
        end
      end
      super(param)
    end
  end
end

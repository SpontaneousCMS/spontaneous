# encoding: UTF-8


module Cutaneous
  module ContextHelper
    include Tenjin::ContextHelper
    include Spontaneous


    def extends(parent)
      self._layout = parent
    end

    def block_super
      block_name = @_block_level.last
      @_block_super_calls[block_name].push(@_buf.length - @_block_positions[block_name])
    end

    def block(block_name)
      @_block_super_calls ||= Hash.new { |h, k| h[k] = [] }
      @_block_positions ||= {}
      @_block_content ||= {}
      @_block_level ||= []
      block_name = block_name.to_sym
      @_block_positions[block_name] = @_buf.length
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
        super_calls = @_block_super_calls[block_name]
        result = @_block_content[block_name]
        if !super_calls.empty?
          position = super_calls.pop
          result = result[0...position] << output << (result[(position)..-1] || "")
          if _layout
            if (super_call_position = @_block_super_calls[block_name].last)
              @_block_super_calls[block_name][-1] = super_call_position + position
              @_block_content[block_name] = result
            end
          end
        end
        @_buf << result
      else
        if _layout.nil?
          @_buf << output
        else
          @_block_content[block_name] = output
        end
      end
      output
    end

    def include(filename, locals = {})
      import(filename, true, locals)
    end

    ## include template. 'template_name' can be filename or short name.
    def import(template_name, _append_to_buf=true, locals={})
      _buf = self._buf
      context=self._dup_with_locals(locals)
      output = self._engine.render(template_name, context, layout=false)
      _buf << output if _append_to_buf
      output
    end

    protected

    def _dup_with_locals(locals = {})
      self.dup.tap { |context| context._update(locals) }
    end

    def _decode_params(param, *args)
      unless param.is_a?(String)
        @_render_method ||= "to_#{_format}".to_sym
        if param.respond_to?(@_render_method)
          param = param.send(@_render_method, *args)
        end
        if param.respond_to?(:render)
          param = param.render(_format, self, *args)
        end
      end
      super(param)
    end
  end
end

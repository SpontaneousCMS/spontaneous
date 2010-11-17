
module Spontaneous::Cutaneous
  module ContextHelper
    include Tenjin::ContextHelper
    ## over-ride this in implementations
    def format
      :html
    end
    def extends(parent)
      self._layout = parent
    end

    def block(block_name)
      puts "block #{block_name}"
      block_name = block_name.to_sym
      _block_positions[block_name] = self._buf.length
      _block_level << block_name

      if _block_content.key?(block_name) 
        puts "using saved block :#{block_name} #{_block_content[block_name].inspect}"
        @_buf << _block_content[block_name]
        # _block_positions[block_name] = self._buf.length
        # _block_level << block_name
        # _block_content[block_name] = ''
        nil
      else
        if block_given?
          yield
          output = endblock
          if _layout.nil?
            @_buf << output
          end
          nil
        else
          nil
        end
      end
    end

    def endblock(_block_name=nil)
      # the _block_name param is ignored though could throw warning
      block_name = _block_level.pop || _block_name
      puts "endblock #{block_name}"
      return unless block_name
      p @_buf
      p block_name
      p _block_level
      p _block_positions
        p self._buf
      start_position = _block_positions[block_name]
      p start_position
      output = self._buf[start_position..-1]
      self._buf[start_position..-1] = ''
      _block_content[block_name] = output
      p _block_content
      puts "-"*10
      output
    end

    def include(filename)
      import(filename)
    end

    protected

    def _block_positions
      @_block_positions ||= {}
    end
    def _block_content
      @_block_content ||= {}
    end

    def _block_level
      @_block_level ||= []
    end
  end
end

# encoding: UTF-8


module Spontaneous
  class StyleDefinitions

    attr_reader :store

    def initialize(*inheritance_chain)
      @store = []
      @all = nil
      @superstyles = inheritance_chain.map do |superstyles|
        if superstyles.is_a?(Array)
          supertype, styles = superstyles
          if supertype && styles && supertype.respond_to?(styles)
            supertype.send(styles)
          else
            nil
          end
        else
          superstyles
        end
      end.compact
    end

    def <<(item)
      @store.push(item)
      @all = nil
    end

    def all
      @all ||= \
        begin
          all = @store.dup
          @superstyles.each do |s|
            all += s.all
          end
          all
        end
    end

    def method_missing(method, *args, &block)
      result = \
        case method
        when :[]
          self._get(args.first)
        else
          if all.respond_to?(method)
            all.send(method, *args, &block)
          else
            nil
          end
        end
    end


    def default
      default = all.detect { |s| s.default? } || all.first
    end


    def inspect
      %(#<StyleDefinitions:#{object_id} @store=#{@store.inspect} @superstyles=#{@superstyles}>)
    end

    protected

    def _get(index)
      case index
      when nil
        default
      when Symbol, String
        all.inject({}) { |h, s| h[s.name] = s; h }[index.to_sym]
      else
        all[index]
      end
    end
  end
end

# encoding: UTF-8


module Spontaneous::Collections
  class HashWithFallback < Hash
    def initialize(fallback, use_fallback_proc, obj = nil, &block)
      use_fallback_proc ||= proc { |val| val.nil? }
      @fallback, @use_fallback_proc = fallback, use_fallback_proc
      super(obj, &block)
    end

    def [](key)
      val = super
      if @use_fallback_proc[val]
         val = @fallback[key]
      end
      val
    end
  end
end

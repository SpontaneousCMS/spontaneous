module Spontaneous
  # Based on Concern but extended to allow running of
  # a 'before_include' block before the module is included and before the
  # 'included' block is run
  module Concern
    def self.extended(base)
      base.instance_variable_set("@_dependencies", [])
    end

    def append_features(base)
      if base.instance_variable_defined?("@_dependencies")
        base.instance_variable_get("@_dependencies") << self
        return false
      else
        return false if base < self
        base.class_eval(&@_before_include_block) if instance_variable_defined?("@_before_include_block")
        base.extend const_get("ClassMethods") if const_defined?("ClassMethods")
        super
        @_dependencies.each { |dep| base.send(:include, dep) }
        base.class_eval(&@_included_block) if instance_variable_defined?("@_included_block")
      end
    end

    def included(base = nil, &block)
      if base.nil?
        @_included_block = block
      else
        super
      end
    end

    def before_include(&block)
      @_before_include_block = block
    end
  end
end


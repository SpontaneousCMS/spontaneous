
# thanks to @jnunemaker
# http://github.com/jnunemaker/mongomapper/blob/master/lib/mongo_mapper/plugins.rb

module Spontaneous
  module Plugins
    def plugins
      @plugins ||= []
    end

    def plugin(mod)
      extend  mod::ClassMethods     if mod.const_defined?(:ClassMethods)
      include mod::InstanceMethods  if mod.const_defined?(:InstanceMethods)
      mod.configure(self)           if mod.respond_to?(:configure)
      plugins << mod
    end
  end
end

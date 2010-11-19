# encoding: UTF-8

module Spontaneous
  class ProxyObject
    alias_method :proxy_class, :class
    alias_method :__methods, :methods
    instance_methods.each { |m| undef_method m unless m =~ /^__|send|instance_eval|object_id|proxy_class/ }
  end
end


# encoding: UTF-8

module Spontaneous
  class ProxyObject
    alias_method :proxy_class, :class
    alias_method :__class__, :class
    alias_method :__methods__, :methods
    alias_method :__is_a?, :is_a?
    instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval|object_id|proxy_class/ }
  end
end


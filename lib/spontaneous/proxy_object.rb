# encoding: UTF-8

module Spontaneous
  class ProxyObject
    alias_method :proxy_class, :class
    instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval|object_id|proxy_class/ }
  end
end


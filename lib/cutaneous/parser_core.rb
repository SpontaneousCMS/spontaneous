# encoding: UTF-8

module Cutaneous
  module ParserCore
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    end

    def initialize(filepath=nil, format=:html)
      @format = format
      super(filepath)
    end

    def render(_context=Context.new)
      begin
        super
      rescue => e
        if _context.show_errors?
          raise e
        else
          logger.warn(e)
          ""
        end
      end
    end
  end
end

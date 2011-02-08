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

    def convert_file(filename)
      if filename.is_a?(Proc)
        convert(filename.call, filename.to_s)
      else
        convert(File.read(filename), filename)
      end
    end

  end
end




# encoding: UTF-8

module Cutaneous
  class RequestTemplate < PublishTemplate
    protected

    def parser_class
      Cutaneous::RequestTokenParser
    end
  end
end

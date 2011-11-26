# encoding: UTF-8

module Cutaneous
  class RequestTemplate < PublishTemplate
    protected

    def parser_class
      Cutaneous::ViewTokenParser
    end
  end
end

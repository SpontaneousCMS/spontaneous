# encoding: UTF-8

module Spontaneous::Media::Store
  class Backend
    def accepts?(mimetype)
      return true if @accepts.nil?
      true
    end
  end
end

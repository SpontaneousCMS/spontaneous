# encoding: UTF-8

module Spontaneous::Model::Core
  module Media
    extend Spontaneous::Concern

    def padded_id
      save if media_id.nil?
      Spontaneous::Media.pad_id(media_id)
    end

    def media_id
      id
    end
  end
end

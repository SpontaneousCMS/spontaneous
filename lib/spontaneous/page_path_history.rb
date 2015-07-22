# encoding: UTF-8

module Spontaneous
  class PagePathHistory < Sequel::Model(:spontaneous_page_path_history)
    many_to_one :page, class: :'Spontaneous::Permissions::User'
    plugin :timestamps, create: :created_at
  end
end


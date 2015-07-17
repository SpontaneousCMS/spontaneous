# encoding: UTF-8

module Spontaneous
  class PublishedRevision < Sequel::Model(:revisions)
    many_to_one :user, class: :'Spontaneous::Permissions::User'
  end
end

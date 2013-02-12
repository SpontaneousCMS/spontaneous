
module Spontaneous::Field
  class FieldVersion < Sequel::Model(:spontaneous_field_versions)
    plugin :timestamps

    many_to_one :user, :class => Spontaneous::Permissions::User
  end
end

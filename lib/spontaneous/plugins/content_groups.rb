# encoding: UTF-8

module Spontaneous::Plugins
  module ContentGroups
    extend Spontaneous::Concern

    module ClassMethods
      attr_reader :group_memberships

      def group(*group_names)
        @group_memberships = group_names
        Spontaneous::Site.schema.add_group_member(self, group_names)
      end
    end
  end
end

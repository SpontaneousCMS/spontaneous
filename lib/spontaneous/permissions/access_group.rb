# encoding: UTF-8

module Spontaneous::Permissions
  class AccessGroup < Sequel::Model(:spontaneous_groups)
    many_to_many :members, :class => :'Spontaneous::Permissions::User', :join_table => :spontaneous_groups_users, :left_key => :group_id, :right_key => :user_id

    def level_for(content)
      if selector.matches(content)
        level
      else
        UserLevel.none
      end
    end

    def selector
      @selector ||= Spontaneous::ContentQuery.new(access_selector)
    end

    def level_for(content)
      if selector.matches?(content)
        level
      else
        UserLevel.none
      end
    end

    def level
      if disabled
        UserLevel.none
      else
        UserLevel[level_name]
      end
    end

    def level=(level)
      self.level_name = level.to_s
    end

    def invisible?
      !user_id.blank?
    end

    def validate
      super
      errors.add(:name, 'is required') if name.blank?
    end
  end
end



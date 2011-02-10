# encoding: UTF-8

module Spontaneous::Permissions
  class AccessGroup < Sequel::Model(:spontaneous_groups)
    def level
      UserLevel[level_name]
    end

    def level=(level)
      self.level_name = level.to_s
    end

    def invisible?
      !user_id.blank?
    end
  end
end



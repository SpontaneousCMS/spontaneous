module Spontaneous
  module DataMapper

    def self.timestamp
      ::Sequel.datetime_class.now
    end

    module ContentModel
      module Timestamps
        def before_create
          set_create_timestamp
          super
        end

        def before_update
          set_update_timestamp
          super
        end

        def set_create_timestamp(time=nil)
          return unless self.respond_to?(:created_at)
          time ||= Spontaneous::DataMapper.timestamp
          self.send(:"created_at=", time) if send(:created_at).nil?
          set_update_timestamp(time)
        end

        def set_update_timestamp(time=nil)
          return unless self.respond_to?(:modified_at)
          self.send(:modified_at=, time || Spontaneous::DataMapper.timestamp)
        end
      end
    end
  end
end

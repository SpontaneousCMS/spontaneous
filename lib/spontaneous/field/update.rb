# encoding: UTF-8

module Spontaneous::Field

  class Update
    def self.perform(fields, user, asynchronous = false)
      self.new(fields, user).run(asynchronous)
    end


    def self.asynchronous_update_class
      Spontaneous::Site.resolve_background_mode(self)
    end

    def initialize(fields, user)
      @fields, @user = fields, user
    end

    def run(asynchronous = false)
      fields.each do |field, value|
        field.pending_value = value
      end

      immediate, asynchronous = partition_fields(asynchronous)

      Immediate.process(immediate)

      launch_asynchronous_update(asynchronous)
    end

    def partition_fields(asynchronous)
      fields = self.fields.keys
      return [fields, []] unless asynchronous
      filter    = proc { |f| f.asynchronous? }
      async     = fields.select(&filter)
      immediate = fields.reject(&filter)
      [immediate, async]
    end

    def fields
      writable_fields
    end

    def owners(fields)
      fields.map(&:owner).uniq
    end

    def writable_fields
      @fields.reject { |f, v| !f.writable?(@user)}
    end

    def launch_asynchronous_update(fields)
      return if fields.empty?
      # Keep the saving command here rather than in the field
      # because all the fields most probably belong to
      # the same owner
      owners(fields).each(&:save_fields)
      fields.each do |field|
        prepare_asynchronous_update(field)
      end
      updater = self.class.asynchronous_update_class
      updater.process(fields)
    end

    def prepare_asynchronous_update(field)
      field.before_asynchronous_update
      Spontaneous::PageLock.lock_field(field)
    end

    class Immediate
      def self.process(fields)
        self.new(fields).run
      end

      def initialize(fields)
        @fields = fields
      end

      def run
        @fields.each do |field|
          field.process_pending_value
          remove_update_lock(field)
        end
        owners.each(&:save_fields)
      end

      def remove_update_lock(field)
        Spontaneous::PageLock.unlock_field(field)
      end

      def owners
        @fields.map(&:owner).uniq
      end
    end

    class Simultaneous < Immediate
      def run
        params = { "fields" => @fields.map { |f| f.id } }
        begin
          Spontaneous::Simultaneous.fire(:update_fields, params)
        rescue Spontaneous::Simultaneous::Error
          Immediate.process(@fields)
        end
      end
    end
  end
end

Spontaneous::Simultaneous.register(:update_fields, "field update", :logfile => "log/fields.log")

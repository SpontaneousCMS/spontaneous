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
      fields = self.fields
      return [fields.keys, []] unless asynchronous
      filter    = proc { |f, v| f.asynchronous? }
      async     = fields.select(&filter)
      immediate = fields.reject(&filter)
      [immediate.keys, async.keys]
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
      owners(fields).each(&:save_fields)
      updater_class = self.class.asynchronous_update_class
      updater_class.process(fields)
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
        end
        owners.each(&:save_fields)
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

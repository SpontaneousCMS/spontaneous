# encoding: UTF-8

module Spontaneous::Field

  class Update
    def self.perform(site, fields, user, asynchronous = false)
      self.new(site, fields, user).run(asynchronous)
    end


    def self.asynchronous_update_class(site)
      site.resolve_background_mode(self)
    end

    def initialize(site, fields, user)
      @site, @fields, @user = site, fields, user
    end

    def run(asynchronous = false)
      fields.each do |field, value|
        field.set_pending_value(value, @site)
      end

      immediate, asynchronous = partition_fields(asynchronous)

      Immediate.process(@site, immediate)

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
      @fields.reject { |f, v| f.nil? || !f.writable?(@user) }
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
      updater = self.class.asynchronous_update_class(@site)
      updater.process(@site, fields)
    end

    def prepare_asynchronous_update(field)
      field.before_asynchronous_update
      Spontaneous::PageLock.lock_field(field)
    end

    class Immediate
      def self.process(site, fields)
        self.new(site, fields).run
      end

      def initialize(site, fields)
        @site, @fields = site, Array(fields)
      end

      def run
        @site.transaction do
          run!
        end
      end

      def run!
        @fields.each do |field|
          field.process_pending_value(@site)
        end
        save
      end

      # This is made more complex by the need to verify that:
      #
      #   a. this update has not been superceded by a more recent one and
      #   b. other fields on the owner have not been updated synchronously since
      #      this update was launched.
      #
      # (a) is verified by only saving fields that pass the #validate_update!
      # test.
      #
      # (b) by calling Content#save_fields on a reloaded version of the owner
      # and by the fact that only the fields that have been modified by this
      # updater are re-serialized.
      #
      def save
        valid_fields = @fields.reject { |field| field.invalid_update? || field.conflicted_update? }
        remove_update_lock(valid_fields)
        field_map = valid_fields.group_by { |f| f.owner }
        field_map.each do |owner, fields|
          reload(owner).save_fields(fields)
        end
      end

      # We need to save against a fresh version of the owning content
      # because with long-running updates (video transcoding for example)
      # it's quite likely that some non-asynchronous fields have been modified
      # during the processing period.
      #
      # The #save_fields method only re-serializes the fields it's passed
      # so we can update the fields we have updated without over-writing the db
      # versions of any other fields.
      def reload(owner)
        owner.model.scope! do
          o = owner.model.get(owner.content_instance.id)
          return o.boxes[owner.box_name] if Spontaneous::Box === owner
          o
        end
      end


      def remove_update_lock(fields)
        fields.each do |field|
          Spontaneous::PageLock.unlock_field(field)
        end
      end

      def owners
        @fields.map(&:owner).uniq.compact
      end

      # Load these everytime to ensure they are updated with their
      # correct lock status
      def pages
        pages = owners.map { |owner| [owner.model, owner.page] }.uniq
        pages = pages.reject { |model, page| page.nil? }.map { |model, page| [model, page.id] }
        pages.map { |model, id| model.get(id) }
      end
    end

    class Simultaneous < Immediate
      def run
        params = { "fields" => @fields.map { |f| f.id } }
        begin
          Spontaneous::Simultaneous.fire(:update_fields, params)
        rescue Spontaneous::Simultaneous::Error
          Immediate.process(@site, @fields)
        end
      end
    end
  end
end

Spontaneous::Simultaneous.register(:update_fields, "field update", :logfile => "log/fields.log")

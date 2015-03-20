# encoding: UTF-8

module Spontaneous::Schema
  class UIDMap

    def self.uid_lock
      @uid_lock ||= Mutex.new
    end

    def self.get_inc
      uid_lock.synchronize do
        @uid_index = ((@uid_index ||= 0) + 1) % 0xFFFF
      end
    end

    def self.generate(ref = nil)
      generate36(ref)
    end

    def self.generate36(ref)
      # reverse the time so that sequential ids are more obviously different
      oid =  (Time.now.to_f * 1000).to_i.to_s(36).reverse
      oid << get_inc.to_s(36).rjust(3, '0')
    end

    include Enumerable

    def initialize(site)
      @site = site
      @instance_lock  = Mutex.new
      @instances = {}
    end

    def load(id, reference)
      @instance_lock.synchronize do
        unless instance = @instances[id]
          instance = UID.new(self, id, reference)
          # check to make sure that the uid is valid first
          # this ensures that UIDs are not created before their owners
          # have uids
          if instance.valid?
            @instances[id] = instance
          else
            instance = nil
          end
        end
        instance
      end
    end

    def create(reference)
      unless instance = @instances.values.detect { |i| i.reference == reference }
        instance = load(self.class.generate(reference), reference)
      end
      instance
    end

    def existing_references
      @instances.values.map { |i| i.reference }
    end

    def create_for(obj)
      id = create(obj.schema_name)
      obj.update_schema_id(id) if obj.respond_to?(:update_schema_id)
    end

    def destroy(uid)
      @instance_lock.synchronize do
        @instances.delete(uid.to_s)
        uid.after_destroy(@site)
      end
    end

    def clear!
      @instances = {}
    end

    def [](id)
      return id if UID === id
      return nil if id.blank?
      @instances[id]
    end

    def get_id(reference)
      find { |uid| uid.reference == reference }
    end

    def each
      uids = @instances.map { |id, instance| instance }
      if block_given?
        uids.each { |instance| yield(instance) }
      else
        uids.each
      end
    end


    def export
      Hash[ @instances.map { |id, ref| [id, ref.reference] } ]
    end
  end # UIDMap
end

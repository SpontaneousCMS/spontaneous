# encoding: UTF-8

module Spontaneous
  module Field
    autoload :Base,         "spontaneous/field/base"
    autoload :FieldVersion, "spontaneous/field/field_version"
    autoload :Update,       "spontaneous/field/update"

    @@type_map = {}

    def self.register(klass, *labels)
      labels.each do |label|
        @@type_map[label.to_sym] = klass
      end
    end

    def self.[](label)
      @@type_map[label.to_sym] || String
    end

    def self.serialize_field(field)
      [field.schema_id.to_s, field.version, field.unprocessed_value, field.processed_values]
    end

    def self.deserialize_field(serialized_field)
      {
        :id => serialized_field[0],
        :version => serialized_field[1],
        :unprocessed_value => serialized_field[2],
        :processed_values => serialized_field[3]
      }
    end

    # Used to test for the validity of asynchronous updates.
    #
    # A to-the-second resolution would actually probably be fine as
    # real updates will come from the user in meat-space time but
    # why not use the full resolution available...
    def self.timestamp(time = Time.now)
      (time.to_f * 10000000).to_i
    end

    def self.update(content, params, user, asynchronous = false)
      fields = Hash[params.map { |sid, value| [content.fields.sid(sid), value] }]
      Update.perform(fields, user, asynchronous)
    end

    def self.update_asynchronously(content, params, user)
      update(content, params, user, true)
    end

    def self.set(field, value, user, asynchronous = false)
      Update.perform({field => value}, user, asynchronous)
    end

    def self.set_asynchronously(field, value, user)
      set(field, value, user, true)
    end

    def self.find(*ids)
      fields = ids.map { |id| resolve_id(id) }.compact
      return fields.first if ids.length == 1
      fields
    end

    def self.resolve_id(id)
      content_id, box_sid, field_sid = id.split("/")
      field_sid, box_sid = box_sid, field_sid if field_sid.nil?
      content = target = Spontaneous::Content.get(content_id)
      return nil if target.nil?
      target  = content.boxes.sid(box_sid) if box_sid
      return nil if target.nil?
      target.fields.sid(field_sid)
    end
  end
end

[:string, :long_string, :file, :image, :date, :markdown, :location, :webvideo, :select].each do |type|
  require "spontaneous/field/#{type}"
end

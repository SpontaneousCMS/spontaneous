# encoding: UTF-8


module Spontaneous
  module FieldTypes
    class Base

      def self.register(*labels)
        labels = self.labels if labels.empty?
        FieldTypes.register(self, *labels)
        self
      end

      def self.labels
        [self.name.demodulize.gsub(/Field$/, '').underscore]
      end

      # def self.prototype=(prototype)
      #   @prototype = prototype
      # end

      # def self.prototype
      #   @prototype
      # end

      def self.accepts
        %w(text/.+)
      end

      def self.accepts?(mime_type)
        accepts.find do |pattern|
          Regexp.new(pattern).match(mime_type)
        end
      end

      attr_accessor :owner, :name, :unprocessed_value, :template_params
      attr_reader   :processed_value



      def initialize(attributes={}, from_db=false)
        load(attributes, from_db)
      end


      def unprocessed_value=(v)
        set_unprocessed_value(v)
        unless @preprocessed
          self.processed_value = process(@unprocessed_value)
          owner.field_modified!(self) if owner
        end
      end

      # should be overwritten in subclasses that actually do something
      # with the field value
      def process(value)
        value
      end

      # override this to return custom values derived from (un)processed_value
      alias_method :value, :processed_value
      # def value
      #   processed_value
      # end


      def to_s
        value.to_s
      end

      def to_html(*args)
        value
      end

      def to_pdf(*args)
        value
      end

      def value=(value)
        self.unprocessed_value = value
      end

      attr_accessor :prototype
      # def prototype
      #   self.class.prototype
      # end

      def schema_id
        self.prototype.schema_id
      end


      def schema_name
        self.prototype.schema_name
      end

      def schema_owner
        self.prototype.owner
      end

      def owner_sid
        schema_owner.schema_id
      end

      def serialize
        {
          :id => schema_id.to_s,
          :unprocessed_value => unprocessed_value,
          :processed_value => processed_value,
          :attributes => serialized_attributes
        }
      end


      def serialized_attributes
        self.attributes.keys.inject({}) do |hash, attribute|
          hash[attribute] = attributes[attribute]
          hash
        end
      end

      def attributes
        @attributes ||= {}
      end

      def attributes=(attr)
        @attributes = attr
      end

      def attribute_get(attribute, *args)
        attributes[attribute.to_sym]
      end

      def attribute_set(attribute, value)
        attributes[attribute.to_sym] = value
      end

      def has_attribute?(attribute_name)
        attributes.key?(attribute_name.to_sym)
      end

      def update(attributes={})
        attributes.each do |property, value|
          setter = "#{property}=".to_sym
          if respond_to?(setter)
            self.send(setter, value)
          end
        end
      end

      # def start_inline_edit_marker
      #   "spontaneous:previewedit:start:field id:#{owner.id} name:#{self.name}"
      # end
      # def end_inline_edit_marker
      #   "spontaneous:previewedit:end:field id:#{owner.id} name:#{self.name}"
      # end

      def to_hash
        {
        :name => name.to_s,
        :id => schema_id.to_s,
        :unprocessed_value => unprocessed_value,
        :processed_value => processed_value,
        :attributes => attributes
        }
      end

      def inspect
        %(#<#{self.class.name}:#{self.object_id} #{self.serialize.inspect}>)
      end

      protected

      def load(attributes={}, from_db=false)
        with_preprocessed_values(from_db) do
          attributes.each do |property, value|
            setter = "#{property}=".to_sym
            if respond_to?(setter)
              self.send(setter, value)
            end
          end
        end
      end

      def processed_value=(value)
        @processed_value = value
      end

      def with_preprocessed_values(state=true)
        @preprocessed = state
        yield
      ensure
        @preprocessed = nil
      end

      def method_missing(method_name, *args)
        if self.has_attribute?(method_name)
          attribute_get(method_name, *args)
        else
          super
        end
      end

      def set_unprocessed_value(value)
        @unprocessed_value = value
      end

    end
  end
end

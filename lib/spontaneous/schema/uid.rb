# encoding: UTF-8

module Spontaneous
  module Schema
    class UID

      REFERENCE_SEP = "/".freeze

      include Comparable

      attr_reader :reference, :name, :category, :map

      def initialize(map, id, reference)
        @map = map
        @id = id.freeze
        read_reference(reference)
      end

      def read_reference(reference)
        @reference = reference
        @category, @owner_sid, @name = reference.split(REFERENCE_SEP)
        @category = @category.to_sym
        @name = Spontaneous::Schema.decode_schema_name(@name)
      end

      def destroy
        map.destroy(self)
      end

      def after_destroy(site)
        case @category
        when :box
          site.model.filter(:box_sid  => @id).delete
        end
      end

      def rewrite!(target)
        target = target.schema_name if target.respond_to?(:schema_name)
        read_reference(target)
        @target = nil
      end

      def target
        @target ||= find_target
      end

      def valid?
        case @category
        when :type
          true
        else
          owner_sid
        end
      end

      def orphaned?
        target.nil?
      end

      def find_target
        case @category
        when :type
          begin
            @name.constantize
          rescue NameError => e
            nil
          end
        else
          if owner
            prototypes = \
              case @category
              when :box
                owner.box_prototypes
              when :field
                owner.field_prototypes
              when :style
                owner.style_prototypes
              when :layout
                owner.layout_prototypes
              end
            prototypes[name.to_sym]
          else
            nil
          end
        end
      end

      def owner
        return nil if owner_sid.nil?
        owner_sid.target
      end

      alias_method :schema_owner, :owner

      def owner_sid
        map[@owner_sid]
      end

      def source_file
        if owner
          owner.__source_file
        elsif target
          target.__source_file
        else
          nil
        end
      end

      def ==(obj)
        super or (obj == @id)
      end

      def eql?(obj)
        super or (obj.is_a?(Spontaneous::Schema::UID) and obj.to_s == @id)
      end

      def hash
        @id.hash
      end

      def to_s
        @id
      end

      def sql_literal(dataset)
        dataset.literal @id
      end

      def <=>(other)
        self.to_s <=> other.to_s
      end

      def to_json(options = {})
        Spontaneous::JSON.encode(to_s)
      end

      def inspect
        %(#<#{self.class}:"#{@id}" => "#{reference}">)
      end
    end
  end
end

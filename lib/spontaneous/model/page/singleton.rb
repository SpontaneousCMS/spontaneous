# encoding: UTF-8

module Spontaneous::Model::Page
  module Singleton
    extend Spontaneous::Concern

    module SiteMethods
      def singletons
        @singletons ||= {}
      end

      def singleton?(label)
        singletons.key?(label.to_s)
      end

      def add_singleton_class(type, labels)
        ([default_type_label(type)] + labels).map(&:to_sym).each do |label|
          singletons[label.to_s] = true
          unless respond_to?(label)
            define_singleton_method(label) { type.instance }
          end
        end
      end

      # Provide a default singleton label e.g.
      #
      #   Something::Else     => :something_else
      #   Something::ThenElse => :something_then_else
      #   ThenElse            => :then_else
      #
      def default_type_label(type)
        type.name.gsub(/::/, '_').underscore
      end
    end

    module AllowedTypeMethods
      def exclude_type?(type)
        return true if (type.singleton? && type.exists?)
        super
      end
    end

    module ContentClassMethods
      def singleton?
        @is_singleton || false
      end
    end

    module ClassMethods
      def singleton(*labels)
        @is_singleton = true
        extend  SingletonClassMethods
        include SingletonInstanceMethods
        set_singleton_aliases(labels)
      end
    end

    module SingletonClassMethods
      def set_singleton_aliases(labels)
        schema.site.add_singleton_class(self, labels)
      end

      def instance
        mapper.with_cache("#{self}_singleton_instance") { first }
      end

      def exists?
        !instance.nil?
      end

      def export(user = nil)
        super.merge(is_singleton: true)
      end
    end

    module SingletonInstanceMethods
      def before_save
        raise Spontaneous::SingletonException.new(self) if (new? && model.exists?)
        super
      end
    end
  end
end

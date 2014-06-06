# encoding: UTF-8

module Spontaneous::Model::Page
  module Singleton
    extend Spontaneous::Concern

    module SiteMethods
      def add_singleton_class(type, labels)
        ([type.name.demodulize.underscore] + labels).map(&:to_sym).each do |label|
          define_singleton_method(label) { type.instance }
        end
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
        raise Spontaneous::SingletonException.new(self) if model.exists?
        super
      end
    end
  end
end

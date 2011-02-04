# encoding: UTF-8


module Spontaneous::Plugins
  module Prototypes
    S = Spontaneous unless defined?(S)

    def self.configure(base)
    end

    module ClassMethods

      ## this is the Sequel default:
      #
      # def create(values = {}, &block)
      #   new(values, &block).save
      # end

      def create_without_prototype(values = {}, &block)
        create(false, values, &block)
      end

      ##
      # Create a new content instance
      def create(*args, &block)
        first = args.shift
        prototype = values = nil
        case first
        when Symbol, false
          prototype = first
          values = args.shift || {}
        when Hash
          values = first
        else
          values = {}
        end
        new(values.merge(:_prototype => prototype), &block).save
      end
    end # ClassMethods

    module InstanceMethods

      def after_create
        super
        apply_prototype
      end

      protected

      DEFAULT_PROTOTYPE_METHOD = :prototype unless defined?(DEFAULT_PROTOTYPE_METHOD)

      def apply_prototype
        return if _prototype == false
        prototype_method = DEFAULT_PROTOTYPE_METHOD
        unless _prototype.blank?
          prototype_method = "#{_prototype}_prototype".to_sym
        end

        if respond_to?(prototype_method)
          self.__send__(prototype_method)
          save
        else
          logger.warn {
            "Invalid prototype name '#{_prototype}' being passed to class #{self.class}. No method #{prototype_method} available."
          } unless prototype_method == DEFAULT_PROTOTYPE_METHOD
        end
      end

      def _prototype=(prototype)
        @_prototype = prototype
      end

      def _prototype
        @_prototype
      end

    end # InstanceMethods

  end
end





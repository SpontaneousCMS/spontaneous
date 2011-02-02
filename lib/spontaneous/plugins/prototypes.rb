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

      ##
      # Create a new content instance
      def create(*args, &block)
        first = args.shift
        prototype = values = nil
        case first
        when Symbol
          prototype = first
          values = args.shift || {}
        when Hash
          values = first
        else
          values = {}
        end
        instance = new(values.merge(:_prototype => prototype), &block)
        instance.save
      end
    end # ClassMethods

    module InstanceMethods

      def after_create
        super
        apply_prototype
      end

      protected

      def apply_prototype
        initialize_slots!
        if _prototype.blank?
          prototype if respond_to?(:prototype)
        else
          method = "#{_prototype}_prototype".to_sym
          if respond_to?(method)
            self.__send__(method)
          else
            logger.warn {
              "Invalid prototype name '#{_prototype}' being passed to class #{self.class}. No method #{method} available."
            }
          end
        end
        save
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





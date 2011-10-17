# encoding: UTF-8


module Spontaneous::Plugins
  module Prototypes

    DEFAULT_PROTOTYPE_NAME = :__default_prototype unless defined?(DEFAULT_PROTOTYPE_NAME)

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


      def prototypes
        @prototypes ||= Spontaneous::Collections::PrototypeSet.new(supertype, :prototypes)
      end

      def prototype(name = Spontaneous::Plugins::Prototypes::DEFAULT_PROTOTYPE_NAME, &block)
        prototypes[name] = block
      end
    end # ClassMethods

    module InstanceMethods

      def after_create
        super
        apply_prototype
      end

      protected


      def apply_prototype
        return if _prototype == false

        block = self.class.prototypes[_prototype || Spontaneous::Plugins::Prototypes::DEFAULT_PROTOTYPE_NAME]

        if block
          block.call(self)
          save
        else
          logger.warn {
            "Invalid prototype name '#{_prototype}' being passed to class #{self.class}."
          }
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





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


      # Blocks passed to the prototype call are used to create instance methods on the class
      # This enables the use of `super` within the blocks and solves the otherwise tricky
      # inheritance implications.
      def prototype(name = Spontaneous::Plugins::Prototypes::DEFAULT_PROTOTYPE_NAME, &block)
        define_method(prototype_method_name(name), &block)# do |content|
      end

      def prototype_method_name(name)
        "_apply_prototype_#{name}"
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

        method = self.class.prototype_method_name(_prototype || Spontaneous::Plugins::Prototypes::DEFAULT_PROTOTYPE_NAME)

        if respond_to?(method)
          self.send(method, self)
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





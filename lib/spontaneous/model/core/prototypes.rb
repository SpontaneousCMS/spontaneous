# encoding: UTF-8

module Spontaneous::Model::Core
  module Prototypes
    extend Spontaneous::Concern

    DEFAULT_PROTOTYPE_NAME = :__default_prototype unless defined?(DEFAULT_PROTOTYPE_NAME)

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
      def prototype(name = nil, &block)
        raise Spontaneous::InvalidPrototypeDefinitionError.new \
          "Prototype definitions must accept one parameter - " \
          "the content instance which the prototype is about to be applied." \
          unless block.arity == 1
        define_method(prototype_method_name(name), &block)
      end

      def prototype_method_name(name)
        return Spontaneous::Model::Core::Prototypes::DEFAULT_PROTOTYPE_NAME if name.blank?
        "_apply_prototype_#{name}"
      end
    end # ClassMethods

    # InstanceMethods

    def after_create
      apply_prototype
      super
    end

    # Add in an empty default prototype method for subclasses to override
    define_method(Spontaneous::Model::Core::Prototypes::DEFAULT_PROTOTYPE_NAME) { |instance| }

    protected

    def apply_prototype
      # passing _prototype => false to the initialisation skips the prototype
      return if _prototype == false
      method = self.class.prototype_method_name(_prototype)

      if respond_to?(method)
        self.send(method, self)
      else
        logger.warn {
          "Invalid prototype name '#{_prototype}' being passed to class #{self.class}."
        }
      end
      save
    end

    def _prototype=(prototype)
      @_prototype = prototype
    end

    def _prototype
      @_prototype
    end
  end
end

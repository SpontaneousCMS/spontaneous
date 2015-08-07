module Spontaneous
  module DataMapper
    module ContentModel
      module Associations
        def inherited(subclass)
          subclass.instance_variable_set(:@associations, associations.dup)
          subclass.instance_variable_set(:@association_dependencies, association_dependencies.dup)
          super
        end

        # Provided for compatibility with Sequel models.
        #
        # In particular when constructing associations between
        # a content model and a Sequel model, the Sequel
        # association tries to automatically set the reciprocal
        # value and uses Model.all_association_reflections to
        # search for appropriate candidates.
        #
        # Returning an empty array here stops this crashing.
        def all_association_reflections
          []
        end

        def associations
          @associations ||= {}
        end

        def association_method_module
          @association_method_module ||= define_association_method_module
        end

        def define_association_method_module
          m = Module.new
          self.const_set(:AssociationMethods, m)
          self.send :include, m
          m
        end

        ASSOCIATION_MAPPING = {
          :one_to_many=>:before,
          :many_to_one=>:after,
          :many_to_many=>:before,
          :one_to_one=>:before
        }

        def association_dependencies
          @association_dependencies ||= {
            :before_delete=>[], :before_destroy=>[],
            :after_delete=>[], :after_destroy=>[]
          }
        end

        def add_association_dependency(opts)
          if (action = opts[:dependent])
            time = ASSOCIATION_MAPPING[opts[:association]]
            hook = :"#{time}_#{action}"
            association_dependencies[hook] << opts[:dataset_method]
          end
        end

        # Using prepared statements for associations within sqlite causes
        # problems with multiprocess access as preparing the ps within a
        # transaction locks the content table and prevents the field update &
        # publishing processes from updating it
        def associations_use_prepared_statements?
          mapper.use_prepared_statements?
        end

        def has_many_content(name, opts = {})
          opts[:association]    = :one_to_many
          opts[:dataset_method] = "#{name}_dataset"
          opts[:load_ps_method] = "load_#{name}_association_prepared_statement".to_sym
          opts[:ps_method]      = "#{name}_prepared_statement".to_sym
          opts[:ps_name]        = "#{name}_#{opts[:association]}_association".to_sym
          opts[:add_method]     = "add_#{name.to_s.singularize}"
          opts[:load_method]    = "load_#{opts[:association]}_association".to_sym
          opts[:dataset] = Proc.new do |var|
            mapper.where!([[mapper.qualify_column(opts[:key]), var]])
          end
          mod = opts[:module] ||= association_method_module
          if associations_use_prepared_statements?
            define_association_method(mod, opts[:load_ps_method]) {
              ps = self.send(opts[:ps_method])
              ps.call(id: id)
            }
          else
            define_association_method(mod, opts[:load_ps_method]) {
              opts[:dataset].call(id).all
            }
          end
          define_association_method(mod, opts[:ps_method]) {
            mapper.prepare(:select, opts[:ps_name]) { opts[:dataset].call(:$id) }
          }
          define_association_method(mod, opts[:dataset_method]) {
            opts[:dataset].call(id)
          }
          define_association_method(mod, name) { |options = {}|
            load_cached_association(name, options)
          }
          define_association_method(mod, opts[:add_method]) { |member|
            member.send("#{opts[:key]}=", self.id)
            member.save
          }
          add_association_dependency(opts)
          associations[name] = opts
        end

        def belongs_to_content(name, opts = {})
          opts[:association]    = :many_to_one
          opts[:dataset_method] = "#{name}_dataset"
          opts[:add_method]     = "#{name}="
          opts[:load_method]    = "load_#{opts[:association]}_association".to_sym
          opts[:load_ps_method] = "load_#{name}_association_prepared_statement".to_sym
          opts[:ps_method]      = "#{name}_prepared_statement".to_sym
          opts[:ps_name]        = "load_#{name}_#{opts[:association]}_association".to_sym
          opts[:dataset] = Proc.new do |var|
            m = mapper
            m.where!([[m.qualify_column(:id), var]])
          end
          mod = opts[:module] ||= association_method_module

          if associations_use_prepared_statements?
            define_association_method(mod, opts[:load_ps_method]) {
              id = send(opts[:key])
              return nil if id.nil?
              ps = self.send(opts[:ps_method])
              ps.call(id: id)
            }
          else
            define_association_method(mod, opts[:load_ps_method]) {
              id = send(opts[:key])
              return nil if id.nil?
              opts[:dataset].call(id).first
            }
          end
          define_association_method(mod, opts[:ps_method]) {
            mapper.prepare(:first, opts[:ps_name]) { opts[:dataset].call(:$id) }
          }
          define_association_method(mod, opts[:dataset_method]) {
            opts[:dataset].call(send(opts[:key]))
          }
          define_association_method(mod, name) { |options = {}|
            load_cached_association(name, options)
          }
          define_association_method(mod, opts[:add_method]) { |owner|
            set_association_cache(name, owner)
            send("#{opts[:key]}=", owner.id) if owner
          }
          add_association_dependency(opts)
          associations[name] = opts
        end

        alias_method :many_to_one_content, :belongs_to_content

        def define_association_method(mod, name, &block)
          mod.module_eval{ define_method(name, &block) }
        end

        alias_method :one_to_many_content, :has_many_content

        def one_to_many(name, opts={}, &block)
          define_plural_proxy_association(:one_to_many, name, opts, &block)
        end

        alias_method :has_many, :one_to_many

        def many_to_one(name, opts = {}, &block)
          association = define_singular_proxy_association(:many_to_one, name, opts, &block)
          # We need to feed back changes to the association key to the owning
          # content model. It doesn't matter if the proxy class never recieves
          # the message because we don't care about its state at all
          association[:keys].map { |key| "#{key}=" }.each do |method|
            association_proxy_class.class_eval(<<-RB)
              def #{method}(value)
                __content__.send(:#{method}, value)
              end
            RB
          end
          association
        end

        alias_method :belongs_to, :many_to_one

        def one_to_one(name, opts = {}, &block)
          define_singular_proxy_association(:one_to_one, name, opts, &block)
        end

        alias_method :has_one, :one_to_one

        def define_plural_proxy_association(type, name, opts, &block)
          singular = name.to_s.singularize
          plural   = name.to_s.pluralize
          methods = [ name, "#{plural}_dataset", "add_#{singular}", "remove_#{singular}", "remove_all_#{plural}", ]
          define_proxy_association(type, methods, name, opts, &block)
        end

        def define_singular_proxy_association(type, name, opts, &block)
          methods = [ name, "#{name}=", "#{name}_dataset" ]
          define_proxy_association(type, methods, name, opts, &block)
        end

        def define_proxy_association(association, proxy_methods, name, opts = {}, &block)
          assoc = association_proxy_class.send(association, name, opts, &block)
          proxy_methods.each do |method_name|
            association_method_module.module_eval(<<-RB, __FILE__, __LINE__)
              def #{method_name}(*args, &block)
                association_proxy_instance.send(:#{method_name}, *args, &block)
              end
            RB
           end
          assoc
        end

        def association_proxy_class
          @association_proxy_class ||= Class.new(association_proxy_superclass)
        end

        # If we have a superclass that is a content object then we want to
        # inherit its associations. If not then we need to create a base
        # class.
        def association_proxy_superclass
          if superclass.respond_to?(:association_proxy_class)
            superclass.association_proxy_class
          else
            ::Sequel::Model(mapper.table.dataset).tap do |klass|
              klass.send :plugin,      :association_dependencies
              klass.send :attr_reader, :__content__
            end
          end
        end

        module InstanceMethods
          def after_destroy
            super
            model.association_dependencies[:after_delete].each{|m| send(m).delete}
            model.association_dependencies[:after_destroy].each{|m| send(m).destroy}
          end

          def before_destroy
            model.association_dependencies[:before_delete].each{|m| send(m).delete}
            model.association_dependencies[:before_destroy].each{|m| send(m).destroy}
            super
          end

          private

          def association_proxy_instance
            @association_proxy_instance ||= self.class.association_proxy_class.call(attributes).tap do |instance|
              instance.instance_variable_set(:@__content__, self)
            end
          end

          def load_many_to_one_association(assoc)
            self.send(assoc[:load_ps_method])
          end

          def load_one_to_many_association(assoc)
            members = self.send(assoc[:load_ps_method])#.all.compact
            if (reciprocal = assoc[:reciprocal])
              members.each do |member|
                member.send :set_association_cache, reciprocal, self
              end
            end
            members
          end

          def load_cached_association(name, options)
            assoc = model.associations[name]
            clear_association_cache(name) if options[:reload]
            ac = associations_cache
            unless ac.key?(name)
              ac[name] = send(assoc[:load_method], assoc)
            end
            ac[name]
          end

          def associations_cache
            @associations_cache ||= {}
          end

          def set_association_cache(name, value)
            associations_cache[name] = value
          end

          def clear_association_cache(name)
            associations_cache.delete(name)
          end

          def clear_association_cache!
            associations_cache.clear
          end

          def refresh
            clear_association_cache!
            @association_proxy_instance = nil
            super
          end
        end
      end
    end
  end
end

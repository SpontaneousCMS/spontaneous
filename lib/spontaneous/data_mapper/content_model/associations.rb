module Spontaneous
  module DataMapper
    module ContentModel
      module Associations
        def inherited(subclass)
          subclass.instance_variable_set(:@associations, associations.dup)
          subclass.instance_variable_set(:@association_dependencies, association_dependencies.dup)
          super
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

        def has_many(name, opts = {})
          opts[:association] = :one_to_many
          opts[:model] ||= self
          opts[:mapper_method]  = "#{name}_mapper"
          opts[:dataset_method] = "#{name}_dataset"
          opts[:add_method]     = "add_#{name.to_s.singularize}"
          opts[:module]       ||= association_method_module

          where = opts[:model].respond_to?(:where!) ? :where! : :where

          define_association_method(opts, opts[:mapper_method]) {
            opts[:model] == model ? self.mapper : opts[:model]
          }
          define_association_method(opts, opts[:dataset_method]) {
            m = send(opts[:mapper_method])
            c = m.respond_to?(:qualify_column) ? m.send(:qualify_column, opts[:key]) : opts[:key]
            m.send(where, [[c, id]])
          }
          define_association_method(opts, name) { |options = {}|
            cached_has_many_association(name, options)
          }
          define_association_method(opts, opts[:add_method]) { |member|
            member.send("#{opts[:key]}=", self.id)
            member.save
          }
          add_association_dependency(opts)
          associations[name] = opts
        end

        def define_association_method(opts, name, &block)
          opts[:module].module_eval{ define_method(name, &block) }
        end

        alias_method :one_to_many, :has_many

        def belongs_to(name, opts = {})
          opts[:association] = :many_to_one
          opts[:model] ||= self
          opts[:mapper_method]  = "#{name}_mapper"
          opts[:dataset_method] = "#{name}_dataset"
          opts[:add_method]     = "#{name}="
          opts[:module]       ||= association_method_module

          where = opts[:model].respond_to?(:where!) ? :where! : :where

          define_association_method(opts, opts[:mapper_method]) {
            opts[:model] == model ? self.mapper : opts[:model]
          }
          define_association_method(opts, opts[:dataset_method]) {
            m = send(opts[:mapper_method])
            id = send(opts[:key])
            c = m.respond_to?(:qualify_column) ? m.send(:qualify_column, :id) : :id
            m.send(where, [[c, id]])
          }
          define_association_method(opts, name) { |options = {}|
            cached_belongs_to_association(name, options)
          }
          define_association_method(opts, opts[:add_method]) { |owner|
            set_association_cache(name, owner)
            send("#{opts[:key]}=", owner.id) if owner
          }
          add_association_dependency(opts)
          associations[name] = opts
        end

        alias_method :many_to_one, :belongs_to

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

          def cached_belongs_to_association(name, options)
            clear_association_cache(name) if options[:reload]
            ac = associations_cache
            unless ac.key?(name)
              ac[name] = load_belongs_to_association(name)
            end
            ac[name]
          end

          def load_belongs_to_association(name)
            assoc = model.associations[name]
            id    = send(assoc[:key])
            return nil if id.nil?
            self.send(assoc[:mapper_method])[id]
          end

          def cached_has_many_association(name, options)
            clear_association_cache(name) if options[:reload]
            ac = associations_cache
            unless ac.key?(name)
              ac[name] = load_has_many_association(name)
            end
            ac[name]
          end

          def load_has_many_association(name)
            assoc = model.associations[name]
            members = self.send(assoc[:dataset_method]).all
            if (reciprocal = assoc[:reciprocal])
              members.each do |member|
                member.send :set_association_cache, reciprocal, self
              end
            end
            members
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

          def refresh
            associations_cache.clear
            super
          end
        end
      end
    end
  end
end

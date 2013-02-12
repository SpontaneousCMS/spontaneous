module Spontaneous
  module DataMapper
    module ContentModel
      module ColumnAccessors
        def self.included(model)
          m = Module.new
          model.columns.each do |column|
            m.module_eval "def #{column};     _get_column_value(:#{column})    ; end", __FILE__, __LINE__
            m.module_eval "def #{column}=(v); _set_column_value(:#{column}, v) ; end", __FILE__, __LINE__
          end
          model.send :include, m
        end


        def changed_columns
          @changed_columns ||= []
        end

        def _set_column_value(column, value)
          attrs = @attributes
          if new? || !attrs.key?(column) || value != attrs[column]
            _change_column_value(column, value)
          end
        end

        alias_method :[]=, :_set_column_value

        def _change_column_value(column, value)
          _mark_columns_as_modified(column)
          @attributes[column] = value
        end

        def _mark_columns_as_modified(*columns)
          cc = changed_columns
          columns.each { |c| cc << c unless cc.include?(c) }
        end

        def _get_column_value(column)
          @attributes[column]
        end

        alias_method :[], :_get_column_value

        def modified_attributes
          cc = changed_columns
          return @attributes.reject { |col, val| col == :id } if cc.empty? && @modified
          @attributes.reject { |col, val| !cc.include?(col) }
        end
      end
    end
  end
end

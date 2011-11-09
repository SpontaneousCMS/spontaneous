# encoding: UTF-8

module Spontaneous::Plugins::Field
  module EditorClass
    module ClassMethods
      def editor_class
        ui_class
      end
    end
  end
end

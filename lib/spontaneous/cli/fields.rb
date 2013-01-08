
module Spontaneous
  module Cli
    class Fields < ::Thor
      include Spontaneous::Cli::TaskUtils
      namespace :fields

      desc "update", "Performs asynchronous updates on provided fields"
      method_option :fields, :type => :array, :desc => "List of field IDs to update"
      def update
        prepare! :update, :console
        fields = Spontaneous::Field.find(*options.fields)
        Spontaneous::Field::Update::Immediate.new(fields).run
      end
    end
  end
end


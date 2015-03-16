module Spontaneous::Rack
  module Back
    class Base < ServerBase
      helpers  Helpers

      set :views, Proc.new { Spontaneous.application_dir + '/views' }
      set :show_exceptions, false

      def content_model
        site.model
      end

      def update_fields(content, field_data)
        return unless field_data
        Spontaneous::Field.update_asynchronously(site, content, field_data, user)
        json(content)
      end

      def content_for_request(lock = false)
        content_model.db.transaction do
          dataset = lock ? content_model.for_update : content_model
          content = dataset.get(params[:id])
          halt 404 if content.nil?
          content.current_editor = user
          if box_id = content_model.schema.uids[params[:box_id]]
            box = content.boxes.detect { |b| b.schema_id == box_id }
            yield(content, box)
          else
            yield(content)
          end
        end
      end
    end
  end
end

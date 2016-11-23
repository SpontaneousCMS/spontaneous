module Spontaneous::Rack::Back
  class Field < Base
    # Should be a GET as it changes no state but the request can need a lot
    # of data which is best done outside of the query string
    post '/conflicts/:id/?:box_id?' do
      content_for_request(true) do |content, box|
        generate_conflict_list(box || content)
      end
    end

    get '/options/:field_sid/:id/?:box_id?' do
      content_for_request do |content, box|
        field = (box || content).fields.sid(params[:field_sid])
        json(field.option_list)
      end
    end

    def generate_conflict_list(content)
      field_versions = params[:fields]
      conflicts = []
      field_versions.each do |schema_id, version|
        field = content.fields.sid(schema_id)
        if field && field.conflicts_version?(version.to_i)
          conflicts << field
        end
      end
      if conflicts.empty?
        200
      else
        errors = conflicts.map  do |field|
          [field.schema_id.to_s, [field.version, field.conflicted_value]]
        end
        [409, json(Hash[errors])]
      end
    end
  end
end

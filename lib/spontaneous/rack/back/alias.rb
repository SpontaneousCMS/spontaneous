module Spontaneous::Rack::Back
  class Alias < Base
    get '/:schema_id/:id/:box_id' do
      klass = content_model.schema.to_class(params[:schema_id])
      if klass.alias?
        content_for_request do |content, box|
          options = {}
          if (query = params[:query])
            options[:search] = Regexp.new(query, Regexp::IGNORECASE)
          end
          targets = klass.targets(content, box, options).map { |t|
            { :id => t.id,
              :title => t.alias_title,
              :icon => t.exported_alias_icon }
          }
          json({
            :pages => 1,
            :total => targets.length,
            :page => 1,
            :targets => targets
          })
        end
      end
    end

    post '/:id/:box_id' do
      content_for_request(true) do |content, box|
        type = content_model.schema.to_class(params[:alias_id])
        position = (params[:position] || 0).to_i
        if box.writable?(user, type)
          additions = []
          Array(params[:target_ids]).each_with_index do |target_id, offset|
            instance = type.for_target(target_id)
            if instance
              box.insert(position+offset, instance)
              content.save
              additions << { position: position+offset, entry: instance.entry.export(user) }
            end
          end
          json(additions)
        else
          forbidden!
        end
      end
    end
  end
end

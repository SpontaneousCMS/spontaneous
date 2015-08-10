module Spontaneous::Rack::Back
  class Content < Base
    put '/:id/?:box_id?' do
      content_for_request(true) do |content, box|
        target = content
        if box
          forbidden! unless box.writable?(user)
          target = box
        end
        update_fields(target, params[:field])
      end
    end

    post '/:id/:box_id/:type_name' do
      content_for_request(true) do |content, box|
        type = content_model.schema.to_class(params[:type_name])
        forbidden! unless box.writable?(user, type)
        if (params.key?(:after_id) || params.key?('after_id'))
          after_id = (params[:after_id] || params['after_id'])
          add_after_entry(content, box, type, after_id)
        else
          position = (params[:position] || params['position'])
          add_at_position(content, box, type, position)
        end
      end
    end

    delete '/:id' do
      content_for_request(true) do |content|
        forbidden! unless content.box.writable?(user)
        content.destroy
        json({})
      end
    end

    patch '/:id/toggle' do
      content_for_request(true) do |content|
        forbidden! unless content.box && content.box.writable?(user)
        affected = content.toggle_visibility!
        json(affected.map { |a| {id: a.id, hidden: a.hidden?}})
      end
    end

    patch '/:id/position/:position' do
      content_for_request(true) do |content|
        forbidden! unless content.box.writable?(user)
        content.update_position(params[:position].to_i)
        json( {message: 'OK'} )
      end
    end

    protected

    def add_at_position(content, box, type, position)
      position = (position || 0).to_i
      add_item_of_type(content, box, type) { |instance|
        box.insert(position, instance)
        position
      }
    end

    def add_after_entry(content, box, type, entry_id)
      entry_id = Integer(entry_id)
      add_item_of_type(content, box, type) { |instance|
        entry = box.insert_after(entry_id, instance)
        entry.position
      }
    end

    def add_item_of_type(content, box, type, &block)
      instance = type.new(created_by: user)
      position = block.call(instance)
      content.save
      json({
        position: position,
        entry: instance.entry.export(user)
      })
    end
  end
end

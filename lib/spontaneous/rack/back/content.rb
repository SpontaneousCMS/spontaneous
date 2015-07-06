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
        position = (params[:position] || 0).to_i
        type = content_model.schema.to_class(params[:type_name])#.constantize

        forbidden! unless box.writable?(user, type)
        instance = type.new(:created_by => user)
        box.insert(position, instance)
        content.save
        json({
          :position => position,
          :entry => instance.entry.export(user)
        })
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
        json( {:message => 'OK'} )
      end
    end
  end
end

module Spontaneous::Rack::Back
  class Page < Base
    get '/:id' do
      content_for_request { |content| json(content)}
    end

    put '/:id/slug' do
      content_for_request(true) do |content|
        if params[:slug].nil? or params[:slug].empty?
          406 # Not Acceptable
        else
          content.slug = params[:slug]
          if content.siblings.detect { |s| s.slug == content.slug }
            409 # Conflict
          else
            content.save
            json({:path => content.path, :slug => content.slug })
          end
        end
      end
    end

    get '/:id/slug/unavailable' do
      content_for_request do |content|
        json(content.siblings.map { |c| c.slug })
      end
    end

    put '/:id/slug/sync' do
      content_for_request do |page|
        page.sync_slug_to_title
        page.save
        json({:path => page.path, :slug => page.slug })
      end
    end

    put '/:id/uid' do
      forbidden! unless user.developer?
      content_for_request(true) do |content|
        content.uid = params[:uid]
        content.save
        json({:uid => content.uid })
      end
    end

    put '/:id/touch' do
      forbidden! unless user.developer?
      content_for_request(true) do |content|
        timestamp = DateTime.now.to_i.to_s
        content.update(touched_at: timestamp)
        json({ timestamp: timestamp })
      end
    end
  end
end

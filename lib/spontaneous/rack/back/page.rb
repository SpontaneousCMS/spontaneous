module Spontaneous::Rack::Back
  class Page < Base
    get '/page/:id' do
      content_for_request { |content| json(content)}
    end

    put '/page/:id/slug' do
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

    get '/page/:id/slug/unavailable' do
      content_for_request do |content|
        json(content.siblings.map { |c| c.slug })
      end
    end

    put '/page/:id/slug/sync' do
      content_for_request do |page|
        page.slug = page.title.unprocessed_value
        page.save
        json({:path => page.path, :slug => page.slug })
      end
    end

    put '/page/:id/uid' do
      forbidden! unless user.developer?
      content_for_request(true) do |content|
        content.uid = params[:uid]
        content.save
        json({:uid => content.uid })
      end
    end
  end
end

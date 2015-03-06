module Spontaneous::Rack::Back
  class Preview < Base
    include Spontaneous::Rack::Public

    # In preview mode we want to find pages even if they're
    # invisible.
    def with_scope(&block)
      site.model.scope(&block)
    end

    # Redirect to the edit UI if a preview page is being accessed directly
    def ensure_edit_preview(path)
      referer = env['HTTP_REFERER']
      development_preview = Spontaneous.development? && site.model::Page.has_root?
      return true if development_preview || referer || params.key?('preview')
      home = find_page_by_path(path)
      # Need to handle the site initialisation where there is no homepage
      # so we want to force a load of the CMS to offer up the 'add home'
      # dialogue
      if home.nil?
        redirect NAMESPACE
        return false
      end
      redirect "#{NAMESPACE}/#{home.id}/preview"
      false
    end

    # Forward all GETs to the page resolution method
    get '*' do
      path = params[:splat][0]
      ensure_edit_preview(path) && render_path(path)
    end

    # Forward all POSTs to the page resolution method
    post '*' do
      render_path(params[:splat][0])
    end

    # Override the S::Rack::Public method to add in some cache-busting headers
    def render_page(page, format = :html, local_params = {})
      now = Time.now.to_formatted_s(:rfc822)
      response.headers[HTTP_EXPIRES] = now
      response.headers[HTTP_LAST_MODIFIED] = now
      response.headers[HTTP_CACHE_CONTROL] = HTTP_NO_CACHE
      super
    end
  end # Preview
end

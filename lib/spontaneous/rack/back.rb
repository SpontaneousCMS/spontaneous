# encoding: UTF-8

require 'sass'
require 'less'

module Spontaneous
  module Rack
    module Back
      NAMESPACE = "/@spontaneous".freeze
      AUTH_COOKIE = "spontaneous_api_key".freeze

      JAVASCRIPT_FILES = %w(vendor/jquery-1.5.1.min vendor/jquery-ui-1.8.9.custom.min vendor/JS.Class-2.1.5/min/core extensions spontaneous properties dom popover popover_view ajax types content entry page_entry box page field field_types/string_field field_types/file_field field_types/image_field field_types/discount_field field_types/date_field content_area preview editing location state top_bar field_preview box_container progress status_bar upload_manager dialogue edit_dialogue edit_panel add_home_dialogue page_browser publish init load)
      module Authentication
        module Helpers
          def authorised?
            if cookie = request.cookies[AUTH_COOKIE]
              true
            else
              false
            end
          end

          def unauthorised!
            halt 401#, "You do not have the necessary permissions to update the '#{name}' field"
          end

          def api_key
            request.cookies[AUTH_COOKIE]
          end

          def user
            @user ||= load_user
          end

          def load_user
            Spontaneous::Permissions.active_user
            # api_key = request.cookies[AUTH_COOKIE]
            # if api_key && key = Spontaneous::Permissions::AccessKey.authenticate(api_key)
            #   key.user
            # else
            #   nil
            # end
          end
        end

        def self.registered(app)
          app.helpers Authentication::Helpers
          app.post "/login" do
            login = params[:user][:login]
            password = params[:user][:password]
            if key = Spontaneous::Permissions::User.authenticate(login, password)
              response.set_cookie(AUTH_COOKIE, {
                :value => key.key_id,
                :path => '/'
              })
              redirect NAMESPACE, 302
            else
              halt(401, erubis(:login, :locals => { :login => login, :failed => true }))
            end
          end
        end

        def requires_authentication!(options = {})
          exceptions = (options[:except] || []).push("#{NAMESPACE}/login" )
          before do
            # puts "AUTH: path:#{request.path} user:#{user.inspect}"
            # p exceptions.detect { |e| e === request.path }
            unless exceptions.detect { |e| e === request.path }
              unless user
                # halt(401, erubis(:login)) unless user
                halt(401, erubis(:login, :locals => { :login => '' })) unless user
              end
            end
          end
        end

      end


      def self.application
        app = ::Rack::Builder.new do
          # use ::Rack::CommonLogger, STDERR  if Spontaneous.development?
          use ::Rack::Lint
          use ::Rack::ShowExceptions if Spontaneous.development?

          use Spontaneous::Rack::Static, :root => Spontaneous.root / "public",
            :urls => %w[/],
            :try => ['.html', 'index.html', '/index.html']

          # map "#{NAMESPACE}/static" do
          # use Spontaneous::Rack::Static, :root => Spontaneous.application_dir / "static",
          #   :urls => %w[/]
          # end

          map NAMESPACE do
            use Spontaneous::Rack::Static, :root => Spontaneous.application_dir, :urls => %W(/static /js)
            run EditingInterface
          end

          map "/media" do
            run Spontaneous::Rack::Media
          end

          map "/" do
            run Preview
          end
        end
      end

      class EditingInterface < ServerBase

        # use Reloader if Spontaneous::Config.reload_classes
        use ::Rack::Reloader if Spontaneous::Config.reload_classes
        use AroundBack
        register Authentication

        requires_authentication! :except => %w(unsupported static css js).map{ |p| %r(^#{NAMESPACE}/#{p}) }

        set :views, Proc.new { Spontaneous.application_dir + '/views' }

        def json(response)
          content_type 'application/json', :charset => 'utf-8'
          response.to_json
        end

        def update_fields(model, field_data)
          field_data.each do | name, values |
            if model.field_writable?(name.to_sym)
              model.fields[name].update(values)
            else
              unauthorised!
            end
          end
          if model.save
            json(model)
          end
        end

        def content_for_request
          content = Content[params[:id]]
          halt 404 if content.nil?
          if box_id = params[:box_id]
            box = content.boxes[box_id]
            [content, box]
          else
            content
          end
        end

        helpers do
          def scripts(scripts)
            if Spontaneous.development?
              scripts.map do |script|
                src = "/js/#{script}.js"
                path = Spontaneous.application_dir(src)
                size = File.size(path)
                ["#{NAMESPACE}#{src}", size]
                # %(<script src="#{NAMESPACE}/js/#{script}.js" type="text/javascript"></script>)
              end.to_json
            else
              # script bundling + compression
            end
          end
        end

        get '/?' do
          erubis :index
        end

        get '/unsupported' do
          erubis :unsupported
        end

        get '/root' do
          json Site.root
        end

        # TODO: check for perms on the particular bit of content
        # and pass user level into returned JSON
        get '/page/:id' do
          json(content_for_request)
        end

        get '/types' do
          json Schema
        end

        # get '/type/:type' do
        #   klass = params[:type].gsub(/\\./, "::").constantize
        #   json klass
        # end

        get '/map' do
          json Site.map
        end

        get '/map/:id' do
          json Site.map(params[:id])
        end

        get '/location*' do
          if Page.count == 0
            406
          else
            path = params[:splat].first
            page = Site[path]
            json Site.map(page.id)
          end
        end

        post '/root' do
          if Site.root.nil?
            class_name = params[:type].gsub('.', '::')
            type = class_name.constantize
            root = type.create(:title => "Home")
            Spontaneous::Change.push(root)
            json({:id => root.id})
          else
            403
          end
        end

        post '/save/:id' do
          update_fields(content_for_request, params[:field])
        end

        post '/savebox/:id/:box_id' do
          content, box = content_for_request
          if box.writable?
            update_fields(box, params[:field])
          else
            unauthorised!
          end
        end


        post '/content/:id/position/:position' do
          content = content_for_request
          if content.box.writable?
            content.update_position(params[:position].to_i)
            json( {:message => 'OK'} )
          else
            unauthorised!
          end
        end

        post '/toggle/:id' do
          content = content_for_request
          if content.box && content.box.writable?
            content.toggle_visibility!
            json({:id => content.id, :hidden => (content.hidden? ? true : false) })
          else
            unauthorised!
          end
        end


        # Don't think this is actually used
        post '/file/upload/:id' do
          file = params['file']
          media_file = Spontaneous::Media.upload_path(file[:filename])
          FileUtils.mkdir_p(File.dirname(media_file))
          FileUtils.mv(file[:tempfile].path, media_file)
          json({ :id => params[:id], :src => Spontaneous::Media.to_urlpath(media_file), :path => media_file})
        end

        post '/file/replace/:id' do
          content = content_for_request
          file = params['file']
          field = content.fields[params['field']]
          if content.field_writable?(field.name)
            field.unprocessed_value = file
            content.save
            json({ :id => content.id, :src => field.src})
          else
            unauthorised!
          end
        end


        post '/file/wrap/:id/:box_id' do
          content, box = content_for_request
          file = params['file']
          type = box.type_for_mime_type(file[:type])
          if type
            if box.writable?(type)
              position = 0
              instance = type.new
              box.insert(position, instance)
              field = instance.field_for_mime_type(file[:type])
              media_file = Spontaneous::Media.upload_path(file[:filename])
              FileUtils.mkdir_p(File.dirname(media_file))
              FileUtils.mv(file[:tempfile].path, media_file)
              field.unprocessed_value = media_file
              content.save
              json({
                :position => position,
                :entry => instance.entry.to_hash
              })
            else
              unauthorised!
            end
          end
        end

        post '/add/:id/:box_id/:type_name' do
          content, box = content_for_request
          position = 0
          type = params[:type_name].constantize
          if box.writable?(type)
            instance = type.new
            box.insert(position, instance)
            content.save
            json({
              :position => position,
              :entry => instance.entry.to_hash
            })
          else
            unauthorised!
          end
        end

        post '/destroy/:id' do
          content = content_for_request
          if content.box.writable?
            content.destroy
            json({})
          else
            unauthorised!
          end
        end

        post '/slug/:id' do
          content = content_for_request
          if params[:slug].nil? or params[:slug].empty?
            406 # Not Acceptable
          else
            content.slug = params[:slug]
            if content.siblings.detect { |s| s.slug == content.slug }
              409 # Conflict
            else
              content.save
              json({:path => content.path })
            end
          end
        end

        get '/slug/:id/unavailable' do
          content = content_for_request
          json(content.siblings.map { |c| c.slug })
        end

        get '/publish/changes' do
          if user.level.can_publish?
            json(Change.outstanding)
          else
            unauthorised!
          end
        end

        post '/publish/publish' do
          change_sets = (params[:change_set_ids] || []).map(&:to_i)
          if change_sets.empty?
            400
          else
            if user.level.can_publish?
              Site.publish_changes(change_sets)
              json({})
            else
              unauthorised!
            end
          end
        end
        get '/publish/status' do
          json(Spontaneous::Site.publishing_status)
        end

        # get "/favicon.ico" do
        #   puts "Editing/favicon"
        #   send_file(Spontaneous.static_dir / "favicon.ico")
        # end

        get '/static/*' do
          send_file(Spontaneous.static_dir / params[:splat].first)
        end


        get '/js/*' do
          content_type :js
          File.read(Spontaneous.js_dir / params[:splat].first)
        end

        get '/css/*' do
          # need to check for file existing and just send that
          # though production server would handle that I suppose
          # as long as I release pre-compliled CSS files
          file = params[:splat].first
          if file =~ /\.css$/
            content_type :css
            sass_template = Spontaneous.css_dir / File.basename(file, ".css") + ".scss"
            less_template = Spontaneous.css_dir / File.basename(file, ".css") + ".less"
            if File.exists?(sass_template)
              Sass::Engine.for_file(sass_template, :load_paths => [Spontaneous.css_dir], :filename => sass_template, :cache => false).render
            elsif File.exists?(less_template)
              Less::Engine.new(File.new(less_template)).to_css
            else
              raise Sinatra::NotFound
            end
          else
            send_file(Spontaneous.css_dir / file)
          end
        end

      end # EditingInterface

      class Preview < Spontaneous::Rack::Public
        HTTP_EXPIRES = "Expires".freeze
        HTTP_CACHE_CONTROL = "Cache-Control".freeze
        HTTP_LAST_MODIFIED = "Last-Modified".freeze
        HTTP_NO_CACHE = "max-age=0, must-revalidate, no-cache, no-store".freeze

        use AroundPreview
        register Authentication

        set :views, Proc.new { Spontaneous.application_dir + '/views' }

        # I don't want this because I'm redirecting everything to /@spontaneous unless
        # we're logged in
        # requires_authentication! :except => ['/', '/favicon.ico']

        # redirect to /@spontaneous unless we're logged in
        before do
          unless user
            redirect NAMESPACE, 302
          end
        end


        def render_page(page, format = :html, local_params = {})
          now = Time.now.to_formatted_s(:rfc822)
          response.headers[HTTP_EXPIRES] = now
          response.headers[HTTP_LAST_MODIFIED] = now
          response.headers[HTTP_CACHE_CONTROL] = HTTP_NO_CACHE
          super
        end
      end # Preview

    end
  end
end


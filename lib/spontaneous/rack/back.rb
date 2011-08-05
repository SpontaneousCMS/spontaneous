# encoding: UTF-8

require 'sass'
require 'less'

module Spontaneous
  module Rack
    module Back
      NAMESPACE = "/@spontaneous".freeze
      AUTH_COOKIE = "spontaneous_api_key".freeze

      JAVASCRIPT_FILES = %w(vendor/jquery-1.6.2.min vendor/jquery-ui-1.8.9.custom.min vendor/JS.Class-2.1.5/min/core vendor/crypto-2.3.0-crypto vendor/crypto-2.3.0-sha1 extensions spontaneous properties dom authentication user popover popover_view ajax types image content views views/box_view views/page_view views/piece_view views/page_piece_view entry page_entry box page field field_types/string_field field_types/file_field field_types/image_field field_types/markdown_field field_types/date_field content_area preview editing location state top_bar field_preview box_container progress status_bar upload sharded_upload upload_manager dialogue edit_dialogue edit_panel add_home_dialogue page_browser add_alias_dialogue  publish init load)

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
          end
        end

        def self.registered(app)
          app.helpers Authentication::Helpers
          app.post "/reauthenticate" do
            if key = Spot::Permissions::AccessKey.authenticate(params[:api_key])
              response.set_cookie(AUTH_COOKIE, {
                :value => key.key_id,
                :path => '/'
              })
              redirect NAMESPACE, 302
            else
              halt(401, erubis(:login, :locals => { :invalid_key => true }))
            end
          end
          app.post "/login" do
            login = params[:user][:login]
            password = params[:user][:password]
            if key = Spontaneous::Permissions::User.authenticate(login, password)
              response.set_cookie(AUTH_COOKIE, {
                :value => key.key_id,
                :path => '/'
              })
              if request.xhr?
                json({
                  :key => key.key_id,
                  :redirect => NAMESPACE
                })
              else
                redirect NAMESPACE, 302
              end
            else
              halt(401, erubis(:login, :locals => { :login => login, :failed => true }))
            end
          end
        end

        KEY_PARAM = "__key".freeze

        def requires_authentication!(options = {})
          first_level_exceptions = (options[:except_all] || []).concat(["#{NAMESPACE}/login", "#{NAMESPACE}/reauthenticate"] )
          second_level_exceptions = (options[:except_key] || [])
          before do
            unless first_level_exceptions.any? { |e| e === request.path }
              ignore_key = second_level_exceptions.any? { |e| e === request.path }
              valid_key = ignore_key || Spontaneous::Permissions::AccessKey.valid?(params[KEY_PARAM], user)
              unless (user and valid_key)
                halt(401, erubis(:login, :locals => { :login => '' }))
              end
            end
          end
        end
      end


      def self.application
        app = ::Rack::Builder.new do
          use ::Rack::Lint
          use ::Rack::ShowExceptions if Spontaneous.development?

          use Spontaneous::Rack::Static, :root => Spontaneous.root / "public",
            :urls => %w[/],
            :try => ['.html', 'index.html', '/index.html']


          map NAMESPACE do
            use Spontaneous::Rack::Static, :root => Spontaneous.application_dir, :urls => %W(/static /js)
            use AssetsHandler
            use UnsupportedBrowserHandler
            use SchemaModification
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

      class EditingBase < ServerBase
        set :views, Proc.new { Spontaneous.application_dir + '/views' }

        def json(response)
          content_type 'application/json', :charset => 'utf-8'
          response.serialise_http
        end
      end

      class UnsupportedBrowserHandler < EditingBase
        get '/unsupported' do
          erubis :unsupported
        end
      end

      class AuthenticatedHandler < EditingBase

        use AroundBack
        register Authentication
        requires_authentication! :except_all => [%r(^#{NAMESPACE}/unsupported)], :except_key => [%r(^#{NAMESPACE}/?$)]
      end

      class SchemaModification < AuthenticatedHandler

        post "/schema/delete" do
          begin
            Spontaneous::Schema.apply_fix(:delete, params[:uid])
          rescue Spot::SchemaModificationError # ignore remaining errors - they will be fixed later
          end
          redirect(params[:origin])
        end

        post "/schema/rename" do
          begin
            Spontaneous::Schema.apply_fix(:rename, params[:uid], params[:ref])
          rescue Spot::SchemaModificationError # ignore remaining errors - they will be fixed later
          end
          redirect(params[:origin])
        end

      end

      class EditingInterface < AuthenticatedHandler
        use Reloader if Site.config.reload_classes

        set :views, Proc.new { Spontaneous.application_dir + '/views' }


        def update_fields(model, field_data)
          if field_data
            field_data.each do |id, values|
              field = model.fields.sid(id)
              if model.field_writable?(field.name.to_sym)
                field.update(values)
              else
                unauthorised!
              end
            end
          end
          if model.save
            json(model)
          end
        end

        def content_for_request
          content = Content[params[:id]]
          halt 404 if content.nil?
          if box_id = Spontaneous::Schema::UID[params[:box_id]]
            box = content.boxes.detect { |b| b.schema_id == box_id }
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

        get '/root' do
          json Site.root
        end

        get '/user' do
          json(user)
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
          map = Site.map(params[:id])
          if map
            json(map)
          else
            404
          end
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
            type = Spontaneous::Schema[params[:type]]
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


        # TODO: DRY this up
        post '/file/replace/:id' do
          target = content_for_request
          file = params['file']
          field = target.fields.sid(params['field'])
          if target.field_writable?(field.name)
            field.unprocessed_value = file
            target.save
            json({ :id => target.id, :src => field.src})
          else
            unauthorised!
          end
        end

        post '/file/replace/:id/:box_id' do
          content, box = content_for_request
          target = box || content
          file = params['file']
          field = target.fields.sid(params['field'])
          if target.field_writable?(field.name)
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
                :entry => instance.entry.export
              })
            else
              unauthorised!
            end
          end
        end

        post '/add/:id/:box_id/:type_name' do
          content, box = content_for_request
          position = 0
          type = Spontaneous::Schema[params[:type_name]]#.constantize
          if box.writable?(type)
            instance = type.new
            box.insert(position, instance)
            content.save
            json({
              :position => position,
              :entry => instance.entry.export
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

        post '/uid/:id' do
          if user.developer?
            content = content_for_request
            content.uid = params[:uid]
            content.save
            json({:uid => content.uid })
          else
            unauthorised!
          end
        end

        get '/targets/:schema_id' do
          klass = Spontaneous::Schema[params[:schema_id]]
          if klass.alias?
            targets = klass.targets.map do |t|
              {
                :id => t.id,
                :title => t.alias_title,
                :icon => t.alias_icon_field.export
              }
            end
            json(targets)
          end
        end

        post '/alias/:id/:box_id' do
          content, box = content_for_request
          type = Spontaneous::Schema[params[:alias_id]]
          position = 0
          if box.writable?(type)
            target = Spontaneous::Content[params[:target_id]]
            if target
              instance = type.create(:target => target)
              box.insert(position, instance)
              content.save
              json({
                :position => position,
                :entry => instance.entry.export
              })
            end
          else
            unauthorised!
          end
        end

        get '/publish/changes' do
          if user.level.can_publish?
            json(Change)
          else
            unauthorised!
          end
        end

        post '/publish/publish' do
          ids = params[:change_set_ids]
          ids = ids.blank? ? [] : ids
          change_sets = ids.map(&:to_i)
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

        get '/shard/:sha1' do
          shard = Spontaneous.shard_path(params[:sha1])
          if ::File.file?(shard)
            # touch the shard file so that clean up routines can delete unmodified files
            # without affecting any uploads in progresss
            FileUtils.touch(shard)
            200
          else
            404
          end
        end

        post '/shard/:sha1' do
          file = params[:file]
          uploaded_hash = Spontaneous::Media.digest(file[:tempfile].path)
          if uploaded_hash == params[:sha1] # rand(10000) % 2 == 0 # use to test shard re-uploading
            shard_path = Spontaneous.shard_path(params[:sha1])
            FileUtils.mv(file[:tempfile].path, shard_path)
            200
          else
            ::Rack::Utils.status_code(:conflict) #409
          end
        end

        post '/shard/replace/:id' do
          target = content_for_request
          field = target.fields.sid(params[:field])
          if target.field_writable?(field.name)
            Spontaneous::Media.combine_shards(params[:shards]) do |combined|
              field.unprocessed_value = {
                :filename => params[:filename],
                :tempfile => combined
              }
              target.save
            end
            json({ :id => target.id, :src => field.src})
          else
            unauthorised!
          end
        end

        # TODO: remove duplication here
        post '/shard/wrap/:id/:box_id' do
          content, box = content_for_request
          type = box.type_for_mime_type(params[:mime_type])
          if type
            if box.writable?(type)
              position = 0
              instance = type.new
              box.insert(position, instance)
              field = instance.field_for_mime_type(params[:mime_type])
              Spontaneous::Media.combine_shards(params[:shards]) do |combined|
                field.unprocessed_value = {
                  :filename => params[:filename],
                  :tempfile => combined
                }
                content.save
              end
              json({
                :position => position,
                :entry => instance.entry.export
              })
            else
              unauthorised!
            end
          end
        end
        # get "/favicon.ico" do
        #   puts "Editing/favicon"
        #   send_file(Spontaneous.static_dir / "favicon.ico")
        # end


      end # EditingInterface



      # Assets are separata from the main editing handlers so that I can still access them
      # in the case of a Schema modification error
      class AssetsHandler < ::Sinatra::Base
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
      end

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


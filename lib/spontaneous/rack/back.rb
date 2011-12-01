# encoding: UTF-8

require 'sass'
require 'less'

module Spontaneous
  module Rack
    module Back
      include Assets

      def self.messenger
        @messenger ||= ::Spontaneous::Rack::EventSource.new
        # Find a way to move this into a more de-centralised place
        # at some point we are going to want to have some configurable, extendable
        # list of event handlers
        Simultaneous.on_event("publish_progress") { |event|
          @messenger.deliver_event(event)
        }
        @messenger
      end

      def self.application
        messenger = self.messenger
        app = ::Rack::Builder.new do
          # use ::Rack::ShowExceptions if Spontaneous.development?
          # AFAIK the only non-thread-safe part of the stack are the renderer calls
          # because they rely on the global values of renderer and also Content.with_visible
          # I'm not sure that using Rack::Lock here would fix any problems that this causes,
          # or even if there are any problems that would be caused
          #
          # use ::Rack::Lock
          # ###################
          # Looking at the three Around* middlewares, there shouldn't actually be a problem with
          # the renderers, as the only conflict would come from the back server which provides two
          # outputs: the preview and the editing interface. Luckily both the preview and the editing
          # interface share the same renderer.
          # The real problem is the Content::with_visible wrapper as the editing interface and the preview
          # renderer use different values for this. As the only way to solve this would be using a global
          # to replace the model class (as we need to be able to issue thread save Model.select calls)
          # I don't know how to fix this.
          # One solution would be to always use the Content::_unfiltered_dataset call within the editing interface
          # and then we'd be free (I think) to wrap it in the with_visible call, though I don't know how this would
          # affect the loading of content within the page.
          #
          # Needs testing...
          # ###################

          use Spontaneous::Rack::Static, :root => Spontaneous.root / "public",
            :urls => %w[/],
            :try => ['.html', 'index.html', '/index.html']

          ################### REMOVE THIS
          # map "#{NAMESPACE}/lock" do
          #   run proc {
          #     Spontaneous.database.transaction do
          #       Spontaneous.database.run("LOCK TABLES content WRITE, spontaneous_access_keys READ")
          #       puts S::Content.first
          #       Spontaneous.database.run("SELECT SLEEP(10)")
          #       Spontaneous.database.run("UNLOCK TABLES")
          #     end
          #   }
          # end
          # map "#{NAMESPACE}/unlock" do
          #   run proc { Spontaneous.database.run("UNLOCK TABLES") }
          # end
          ################### END REMOVE THIS

          Spontaneous.instance.back_controllers.each do |namespace, controller_class|
            map namespace do
              run controller_class
            end
          end if Spontaneous.instance

          # Make all the files available under plugin_name/public/**
          # available under the URL /plugin_name/**
          Spontaneous.instance.plugins.each do |plugin|
            root = plugin.paths.expanded(:public)
            map "/#{plugin.file_namespace}" do
              use Spontaneous::Rack::CSS, :root => root
              run ::Rack::File.new(root)
            end
          end if Spontaneous.instance

          map "#{NAMESPACE}/events" do
            use CookieAuthentication
            use QueryAuthentication
            run messenger.app
          end

          map NAMESPACE do
            use ::Rack::Lint
            use Spontaneous::Rack::Static, :root => Spontaneous.application_dir, :urls => %W(/static /js)
            use AssetsHandler
            use UnsupportedBrowserHandler
            use SchemaModification
            run EditingInterface
          end

          map "/media" do
            use ::Rack::Lint
            run Spontaneous::Rack::CacheableFile.new(Spontaneous.media_dir)
          end

          map "/" do
            use ::Rack::Lint
            use Spontaneous::Rack::CSS, :root => Spontaneous.instance.paths.expanded(:public)
            run Preview
          end
        end
      end

      class EditingBase < ServerBase
        set :views, Proc.new { Spontaneous.application_dir + '/views' }
        set :environment, Proc.new { Spontaneous.env }

        helpers Spontaneous::Rack::UserHelpers
        helpers Spontaneous::Rack::Helpers

        def json(response)
          content_type 'application/json', :charset => 'utf-8'
          response.serialise_http(user)
        end
      end

      class UnsupportedBrowserHandler < EditingBase
        get '/unsupported' do
          erb :unsupported
        end
      end

      class BackControllerBase < EditingBase
        # use CookieAuthentication
        # use AroundBack
        # register Authentication
      end
      Spontaneous::Rack.make_back_controller(BackControllerBase)

      class AuthenticatedHandler < BackControllerBase
        requires_authentication! :except_all => [%r(^#{NAMESPACE}/unsupported)], :except_key => [%r(^#{NAMESPACE}/?(/\d+/?.*)?$)]
      end

      class SchemaModification < AuthenticatedHandler

        post "/schema/delete" do
          begin
            Spontaneous.schema.apply_fix(:delete, params[:uid])
          rescue Spot::SchemaModificationError # ignore remaining errors - they will be fixed later
          end
          redirect(params[:origin])
        end

        post "/schema/rename" do
          begin
            Spontaneous.schema.apply_fix(:rename, params[:uid], params[:ref])
          rescue Spot::SchemaModificationError => e # ignore remaining errors - they will be fixed later
          end
          redirect(params[:origin])
        end

      end

      class EditingInterface < AuthenticatedHandler
        use Reloader if Site.config.reload_classes

        set :views, Proc.new { Spontaneous.application_dir + '/views' }


        def update_fields(model, field_data)
          conflicts = []
          if field_data
            field_data.each do |id, values|
              field = model.fields.sid(id)
              if model.field_writable?(user, field.name.to_sym)
                # version = values.delete("version").to_i
                # if version == field.version
                field.update(values)
                # else
                #   conflicts << [field, values]
                # end
              else
                unauthorised!
              end
            end
          end
          if conflicts.empty?
            if model.save
              json(model)
            end
          else
            errors = conflicts.map  do |field, new_value|
              [field.schema_id.to_s, [field.version, field.conflicted_value, new_value["unprocessed_value"]]]
            end
            [409, json(Hash[errors])]
          end
        end

        def content_for_request(lock = false)
          Content.db.transaction {
            dataset = lock ? Content.for_update : Content
            content = dataset.first(:id => params[:id])
            halt 404 if content.nil?
            if box_id = Spontaneous.schema.uids[params[:box_id]]
              box = content.boxes.detect { |b| b.schema_id == box_id }
              yield(content, box)
            else
              yield(content)
            end
          }
        end

        post "/reauthenticate" do
          if key = Spot::Permissions::AccessKey.authenticate(params[:api_key])
            response.set_cookie(AUTH_COOKIE, {
              :value => key.key_id,
              :path => '/'
            })
            origin = "#{NAMESPACE}#{params[:origin]}"
            redirect origin, 302
          else
            show_login_page( :invalid_key => true )
          end
        end

        post "/login" do
          login = params[:user][:login]
          password = params[:user][:password]
          origin = "#{NAMESPACE}#{params[:origin]}"
          if key = Spontaneous::Permissions::User.authenticate(login, password)
            response.set_cookie(AUTH_COOKIE, {
              :value => key.key_id,
              :path => '/'
            })
            if request.xhr?
              json({
                :key => key.key_id,
                :redirect => origin
              })
            else
              redirect origin, 302
            end
          else
            show_login_page( :login => login, :failed => true )
          end
        end

        get '/?' do
          erb :index
        end

        get %r{^/(\d+/?.*)?$} do
          erb :index
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
          content_for_request { |content| json(content)}
        end

        get '/types' do
          json Site.schema
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
            type = Spontaneous.schema[params[:type]]
            root = type.create(:title => "Home")
            Spontaneous::Change.push(root)
            json({:id => root.id})
          else
            403
          end
        end

        post '/version/:id' do
          content_for_request(true) do |content|
            generate_conflict_list(content)
          end
        end

        post '/version/:id/:box_id' do
          content_for_request(true) do |content, box|
            generate_conflict_list(box)
          end
        end

        def generate_conflict_list(content)
          field_versions = params[:fields]
          conflicts = []
          field_versions.each do |schema_id, version|
            field = content.fields.sid(schema_id)
            unless field.version == version.to_i
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

        post '/save/:id' do
          content_for_request(true) do |content|
            update_fields(content, params[:field])
          end
        end

        post '/savebox/:id/:box_id' do
          content_for_request(true) do |content, box|
            if box.writable?(user)
              update_fields(box, params[:field])
            else
              unauthorised!
            end
          end
        end


        post '/content/:id/position/:position' do
          content_for_request(true) do |content|
            if content.box.writable?(user)
              content.update_position(params[:position].to_i)
              json( {:message => 'OK'} )
            else
              unauthorised!
            end
          end
        end

        post '/toggle/:id' do
          content_for_request(true) do |content|
            if content.box && content.box.writable?(user)
              content.toggle_visibility!
              json({:id => content.id, :hidden => (content.hidden? ? true : false) })
            else
              unauthorised!
            end
          end
        end


        # TODO: DRY this up
        post '/file/replace/:id' do
          content_for_request(true) do |target|
            file = params['file']
            field = target.fields.sid(params['field'])
            if target.field_writable?(user, field.name)
              # version = params[:version].to_i
              # if version == field.version
              field.unprocessed_value = file
              target.save
              json(field.export(user))
              # else
              #   errors = [[field.schema_id.to_s, [field.version, field.conflicted_value]]]
              #   [409, json(Hash[errors])]
              # end
            else
              unauthorised!
            end
          end
        end

        post '/file/replace/:id/:box_id' do
          content_for_request(true) do |content, box|
            target = box || content
            file = params[:file]
            field = target.fields.sid(params['field'])
            if target.field_writable?(user, field.name)
              # version = params[:version].to_i
              # if version == field.version
              field.unprocessed_value = file
              content.save
              json(field.export(user))
              # else
              #   errors = [[field.schema_id.to_s, [field.version, field.conflicted_value]]]
              #   [409, json(Hash[errors])]
              # end
            else
              unauthorised!
            end
          end
        end


        post '/file/wrap/:id/:box_id' do
          content_for_request(true) do |content, box|
            file = params['file']
            type = box.type_for_mime_type(file[:type])
            if type
              if box.writable?(user, type)
                position = 0
                instance = type.new
                box.insert(position, instance)
                field = instance.field_for_mime_type(file[:type])
                field.unprocessed_value = file
                instance.save
                content.save
                json({
                  :position => position,
                  :entry => instance.entry.export(user)
                })
              else
                unauthorised!
              end
            end
          end
        end

        post '/add/:id/:box_id/:type_name' do
          content_for_request(true) do |content, box|
            position = (params[:position] || 0).to_i
            type = Spontaneous.schema[params[:type_name]]#.constantize
            if box.writable?(user, type)
              instance = type.new
              box.insert(position, instance)
              content.save
              json({
                :position => position,
                :entry => instance.entry.export(user)
              })
            else
              unauthorised!
            end
          end
        end

        post '/destroy/:id' do
          content_for_request(true) do |content|
            if content.box.writable?(user)
              content.destroy
              json({})
            else
              unauthorised!
            end
          end
        end

        post '/slug/:id' do
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

        get '/slug/:id/unavailable' do
          content_for_request do |content|
            json(content.siblings.map { |c| c.slug })
          end
        end

        post '/uid/:id' do
          if user.developer?
            content_for_request(true) do |content|
              content.uid = params[:uid]
              content.save
              json({:uid => content.uid })
            end
          else
            unauthorised!
          end
        end

        get '/targets/:schema_id' do
          klass = Spontaneous.schema[params[:schema_id]]
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
          content_for_request(true) do |content, box|
            type = Spontaneous.schema[params[:alias_id]]
            position = 0
            if box.writable?(user, type)
              target = Spontaneous::Content[params[:target_id]]
              if target
                instance = type.create(:target => target)
                box.insert(position, instance)
                content.save
                json({
                  :position => position,
                  :entry => instance.entry.export(user)
                })
              end
            else
              unauthorised!
            end
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
          content_for_request(true) do |content|
            replace_with_shard(content, content.id)
          end
        end

        post '/shard/replace/:id/:box_id' do
          content_for_request(true) do |content, box|
            replace_with_shard(box, content.id)
          end
        end

        def replace_with_shard(target, target_id)
          field = target.fields.sid(params[:field])
          if target.field_writable?(user, field.name)
            # version = params[:version].to_i
            # if version == field.version
            Spontaneous::Media.combine_shards(params[:shards]) do |combined|
              field.unprocessed_value = {
                :filename => params[:filename],
                :tempfile => combined
              }
              target.save
            end
            json(field.export(user))
            # else
            #   errors = [[field.schema_id.to_s, [field.version, field.conflicted_value]]]
            #   [409, json(Hash[errors])]
            # end
          else
            unauthorised!
          end
        end

        # TODO: remove duplication here
        post '/shard/wrap/:id/:box_id' do
          content_for_request(true) do |content, box|
            type = box.type_for_mime_type(params[:mime_type])
            if type
              if box.writable?(user, type)
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
                  :entry => instance.entry.export(user)
                })
              else
                unauthorised!
              end
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
            css_file = Spontaneous.css_dir / file
            if File.exists?(css_file)
              send_file(css_file)
            else
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
            end
          else
            send_file(Spontaneous.css_dir / file)
          end
        end
      end

      class Preview < Sinatra::Base
        use Reloader if Site.config.reload_classes
        include Spontaneous::Rack::Public
        helpers Spontaneous::Rack::UserHelpers

        use CookieAuthentication
        use AroundPreview

        set :views, Proc.new { Spontaneous.application_dir + '/views' }

        # redirect to /@spontaneous unless we're logged in
        before {
          redirect NAMESPACE, 302 unless user
        }


        get '*' do
          path = params[:splat][0]

          render_path(path)
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

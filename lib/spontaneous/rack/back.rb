# encoding: UTF-8

require 'less'

module Spontaneous
  module Rack
    module Back
      NAMESPACE = "/@spontaneous".freeze

      def self.application
        app = ::Rack::Builder.new {
          # use ::Rack::CommonLogger, STDERR  if Spontaneous.development?
          use ::Rack::Lint
          use ::Rack::ShowExceptions if Spontaneous.development?

          map NAMESPACE do
            run EditingInterface
          end

          map "/" do
            run Preview
          end
        }
      end

      class EditingInterface < ServerBase

        set :views, Proc.new { Spontaneous.application_dir + '/views' }

        def json(response)
          content_type 'application/json', :charset => 'utf-8'
          response.to_json
        end

        def update_fields(model, field_data)
          field_data.each do | name, values |
            model.fields[name].update(values)
          end
          if model.save
            json(model)
          end
        end

        helpers do
          def scripts(*scripts)
            if Spontaneous.development?
              scripts.map do |script|
                src = "/js/#{script}.js"
                path = Spontaneous.application_file(src)
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

        get '/page/:id' do
          json Content[params[:id]]
        end

        get '/types' do
          json Schema
        end

        get '/type/:type' do
          klass = params[:type].gsub(/\./, "::").constantize
          json klass
        end

        get '/map' do
          json Site.map
        end

        get '/map/:id' do
          json Site.map(params[:id])
        end

        get '/location*' do
          path = params[:splat].first
          page = Site[path]
          json Site.map(page.id)
        end

        post '/save/:id' do
          content = Content[params[:id]]
          update_fields(content, params[:field])
        end


        post '/content/:id/position/:position' do
          facet = Content[params[:id]]
          facet.update_position(params[:position].to_i)
          json( {:message => 'OK'} )
        end


        post '/file/upload/:id' do
          file = params['file']
          media_file = Spontaneous::Media.upload_path(file[:filename])
          FileUtils.mkdir_p(File.dirname(media_file))
          FileUtils.mv(file[:tempfile].path, media_file)
          json({ :id => params[:id], :src => Spontaneous::Media.to_urlpath(media_file), :path => media_file})
        end

        post '/file/replace/:id' do
          content = Content[params[:id]]
          file = params['file']
          field = content.fields[params['field']]
          field.unprocessed_value = file
          content.save
          json({ :id => content.id, :src => field.src})
        end


        post '/file/wrap/:id' do
          content = Content[params[:id]]
          file = params['file']
          type = content.type_for_mime_type(file[:type])
          if type
            position = 0
            instance = type.new
            content.insert(position, instance)
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
          end
        end

        post '/add/:id/:type_name' do
          position = 0
          content = Content[params[:id]]
          type = params[:type_name].constantize
          instance = type.new
          content.insert(position, instance)
          content.save
          json({
            :position => position,
            :entry => instance.entry.to_hash
          })
        end

        post '/destroy/:id' do
          content = Content[params[:id]]
          content.destroy
          json({})
        end

        post '/slug/:id' do
          content = Content[params[:id]]
          content.slug = params[:slug]
          content.save
          json({:path => content.path })
        end
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
          file = params[:splat].first
          if file =~ /\.css$/
            less_template = Spontaneous.css_dir / File.basename(file, ".css") + ".less"
            if File.exists?(less_template)
              content_type :css
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
        get "/favicon.ico" do
          send_file(Spontaneous.static_dir / "favicon.ico")
        end
      end # Preview

    end
  end
end


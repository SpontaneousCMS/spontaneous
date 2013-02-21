module Spontaneous::Rack::Back
  class Schema < Base
    # Use the CSRF verification step separately from the main app
    # because it conflicts with the Index application:
    # The index application needs to load without CSRF validation
    # and the Schema app needs CSRF validation
    # but the Schema app has be before Index in the stack
    use Spontaneous::Rack::Middleware::CSRF::Verification

    def schema
      Spontaneous.schema
    end

    post "/delete" do
      begin
        schema.apply_fix(:delete, params[:uid])
      rescue Spot::SchemaModificationError # ignore remaining errors - they will be fixed later
      end
      redirect(params[:origin])
    end

    post "/rename" do
      begin
        schema.apply_fix(:rename, params[:uid], params[:ref])
      rescue Spot::SchemaModificationError => e # ignore remaining errors - they will be fixed later
      end
      redirect(params[:origin])
    end
  end
end

module Spontaneous::Rack::Back
  class Schema < Base
    def schema
      Spontaneous.schema
    end

    post "/schema/delete" do
      begin
        schema.apply_fix(:delete, params[:uid])
      rescue Spot::SchemaModificationError # ignore remaining errors - they will be fixed later
      end
      redirect(params[:origin])
    end

    post "/schema/rename" do
      begin
        schema.apply_fix(:rename, params[:uid], params[:ref])
      rescue Spot::SchemaModificationError => e # ignore remaining errors - they will be fixed later
      end
      redirect(params[:origin])
    end
  end
end

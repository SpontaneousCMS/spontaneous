# encoding: UTF-8

require File.expand_path('../../../test_helper', __FILE__)


describe "Location fields" do
  before do
    @site = setup_site
    @now = Time.now
    stub_time(@now)
    Spontaneous::State.delete
    @site.background_mode = :immediate
    @content_class = Class.new(::Piece) do
      field :location
    end
    @content_class.stubs(:name).returns("ContentClass")
    @instance = @content_class.new
    @field = @instance.location
  end

  it "use a standard string editor" do
    @content_class.fields.location.export(nil)[:type].must_equal "Spontaneous.Field.String"
  end

  it "successfully geolocate an address" do
    # TODO: use mocking to avoid an external API request to googles geolocation service
    @field.value = "Cambridge, England"
    @field.value(:lat).must_equal 52.2053370
    @field.value(:lng).must_equal 0.1218170
    @field.value(:country).must_equal "United Kingdom"
    @field.value(:formatted_address).must_equal "Cambridge, Cambridge, UK"

    @field.latitude.must_equal 52.2053370
    @field.longitude.must_equal 0.1218170
    @field.lat.must_equal 52.2053370
    @field.lng.must_equal 0.1218170

    @field.country.must_equal "United Kingdom"
    @field.formatted_address.must_equal "Cambridge, Cambridge, UK"
  end
end

# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

ENV['RACK_ENV'] = 'test'
describe "Controllers" do
  include RackTestMethods
  start do
    @site_root = Dir.mktmpdir
    let(:root) { @site_root }
    S::State.delete
  end

  finish do
    ::FileUtils.rm_rf(@site_root)
  end

  class Wrappit
    def initialize(app, options = {})
      @app, @options = app, options
    end

    def call(env)
      status, headers, body = @app.call(env)
      with = @options[:with]
      wrapped = body.map { |part| [with, part, with].join("") }
      [status, headers, wrapped]
    end
  end

  before do
    @site = setup_site(root)

    class ::Page
      controller do
        use Wrappit, with: "*"
        set :something, "else"
      end
    end

    class ::SubPage < ::Page
      controller do
        get do
          settings.something
        end
      end

      controller :comments do
        use Wrappit, with: "+"
        get "/" do
          settings.something
        end
      end
    end

    @page = ::SubPage.new(slug: 'something')
  end

  let(:app) { Spontaneous::Rack::Front.application }

  after do
    Object.send(:remove_const, :SubPage) rescue nil
    teardown_site(false)
  end

  describe "requests" do
    before do
      Spontaneous::Site.expects(:by_path).with('/something').returns(@page)
    end

    it "propagates settings to sub-classes" do
      get '/something'
      last_response.body.must_equal "*else*"
    end

    it "propagates settings on the base controller to named controllers" do
      get '/something/@comments'
      last_response.body.must_equal "*+else+*"
    end
  end

  it "sets the type as dynamic" do
    SubPage.dynamic?(:get).must_equal true
    SubPage.dynamic?("GET").must_equal true
    @page.dynamic?(:get).must_equal true
    @page.dynamic?("GET").must_equal true
  end
end

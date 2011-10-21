# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class PluginsTest < MiniTest::Spec
  include ::Rack::Test::Methods


  def self.startup
    # @revision_root = "#{Dir.mktmpdir}/spontaneous-tests/#{Time.now.to_i}"
    # `mkdir -p #{@revision_root}/public`
    @site = instantiate_site

    klass =  Class.new(Spontaneous::Page)
    Object.send(:const_set, :Page, klass)
    klass =  Class.new(Spontaneous::Piece)
    Object.send(:const_set, :Piece, klass)
    klass =  Class.new(::Page) do
      layout :from_plugin
    end
    Object.send(:const_set, :LocalPage, klass)
    klass =  Class.new(::Piece) do
      style :from_plugin
    end
    Object.send(:const_set, :LocalPiece, klass)

    plugin_dir = File.expand_path("../../fixtures/plugins/schema_plugin", __FILE__)
    plugin = Spontaneous.instance.load_plugin plugin_dir
    plugin.init!
    plugin.load!
  end

  def self.shutdown
    FileUtils.rm_rf(@site.root) rescue nil
    Object.send(:remove_const, :Page) rescue nil
    Object.send(:remove_const, :Piece) rescue nil
    Object.send(:remove_const, :LocalPage) rescue nil
    Object.send(:remove_const, :LocalPiece) rescue nil
  end

  def app
    Spontaneous::Rack.application
  end

  context "Plugins:" do

    setup do
      @site = Spontaneous.instance
    end

    teardown do
    end

    should "load their init.rb file" do
      $set_in_init.should be_true
    end

    context "with static files" do
      setup do
        @static = %w(css/plugin.css js/plugin.js subdir/image.gif static.html)
      end

      should "be able to provide them under their namespace in editing mode" do
        Spontaneous.mode = :back
        @static.each do |file|
          get "/schema_plugin/#{file}"
          assert last_response.ok?, "Static file /schema_plugin/#{file} returned error code #{last_response.status}"
          last_response.body.should == File.basename(file) + "\n"
        end
      end

      should "be able to provide them under their namespace in public mode" do
        Spontaneous.mode = :front
        @static.each do |file|
          get "/schema_plugin/#{file}"
          assert last_response.ok?, "Static file /schema_plugin/#{file} returned error code #{last_response.status}"
          last_response.body.should == File.basename(file) + "\n"
        end
      end

      should "look for and parse sass templates" do
        Spontaneous.mode = :back
        get "/schema_plugin/subdir/sass.css"
        assert last_response.ok?, "Static file /schema_plugin/subdir/sass.css returned error code #{last_response.status}"
        last_response.body.should =~ /^\s+color: #005a55;/
        last_response.body.should =~ /^\s+padding: 42px;/
      end

      context "during publishing" do
        setup do

          Content.delete_revision(1) rescue nil

          Spontaneous.logger.silent! {
            Site.publish_all
          }
        end

        teardown do
          FileUtils.rm_rf(@revision_root) rescue nil
          Content.delete
          State.delete
          Content.delete_revision(1)
        end

        should "have their public files copied into the revision sandbox" do
          @static.each do |file|
            path = File.join(@site.revision_root, '00001', 'public', 'schema_plugin', file)
            assert File.exists?(path), "File '#{path}' should exist"
          end
        end

        should "have their SASS & Less templates rendered to static css" do
          sass_files =['subdir/sass.css']
          sass_files.each do |file|
            path = File.join(@site.revision_root, '00001', 'public', 'schema_plugin', file)
            assert File.exists?(path), "File '#{path}' should exist"
            css = File.read(path)
            css.should =~ /color:#005a55;?/
            css.should =~ /padding:42px;?/
          end
        end
      end
    end


    # context "Functional plugins" do
    #   # do I need anything here?
    # end

    context "with schemas" do
      should "make content classes available to rest of app" do
        defined?(::SchemaPlugin).should == "constant"
        ::SchemaPlugin::External.fields.length.should == 1
        piece = ::SchemaPlugin::External.new(:a => "A Field")
        piece.render.should == "plugins/templates/external.html.cut\n"
      end
    end
  end
end

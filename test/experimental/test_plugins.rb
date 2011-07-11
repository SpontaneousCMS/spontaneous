# encoding: UTF-8

require 'test_helper'

class PluginsTest < MiniTest::Spec


  def self.startup
    instance = Spontaneous::Application::Instance.new(Spontaneous.root, :test, :back)
    Spontaneous.instance = instance
    Spontaneous.instance.database = DB

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
    plugin.load!
  end
  def self.shutdown
    Object.send(:remove_const, :Page)
    Object.send(:remove_const, :Piece)
    Object.send(:remove_const, :LocalPage)
    Object.send(:remove_const, :LocalPiece)
  end

  context "Plugins:" do

    setup do
    end

    teardown do
    end

    context "all plugins" do
      should "load their init.rb file" do
        $set_in_init.should be_true
      end
    end

    context "Functional plugins" do
    end

    context "Schema Plugins" do
      should "make content classes available to rest of app" do
        defined?(SchemaPlugin).should == "constant"
        SchemaPlugin::External.fields.length.should == 1
        piece = SchemaPlugin::External.new(:a => "A Field")
        piece.render.should == "plugins/templates/external.html.cut\n"
      end
    end
  end
end

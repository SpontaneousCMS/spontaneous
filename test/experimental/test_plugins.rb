# encoding: UTF-8

require 'test_helper'

class PluginsTest < MiniTest::Spec

  class ::Page < Spontaneous::Page; end
  class ::Piece < Spontaneous::Piece; end
  class ::LocalPage < ::Page
    layout :from_plugin
  end
  class ::LocalPiece < ::Piece
    style :from_plugin
  end

  def self.startup
    plugin_dir = File.expand_path("../../fixtures/plugins/schema_plugin", __FILE__)
    plugin = Spontaneous.load_plugin plugin_dir
    plugin.load!
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

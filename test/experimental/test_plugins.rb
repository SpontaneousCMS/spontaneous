# encoding: UTF-8

require 'test_helper'

class PluginsTest < MiniTest::Spec

  context "Plugins:" do
    setup do
      class ::Page < Spontaneous::Page; end
      class ::Piece < Spontaneous::Piece; end
      class ::LocalPage < ::Page
        layout :from_plugin
      end
      class ::LocalPiece < ::Piece
        style :from_plugin
      end
    end

    teardown do
      Object.send(:remove_const, :Page)
      Object.send(:remove_const, :Piece)
    end

    context "Functional plugins" do
    end

    context "Schema Plugins" do
      setup do
        plugin_dir = File.expand_path("../../fixtures/plugins/schema_plugin", __FILE__)
        plugin = Spontaneous.load_plugin plugin_dir
        plugin.load!
        # p Spontaneous.template_paths
      end

      should "make content classes available to rest of app" do
        defined?(SchemaPlugin).should == "constant"
        SchemaPlugin::External.fields.length.should == 1
        piece = SchemaPlugin::External.new(:a => "A Field")
        piece.render.should == "plugins/templates/external.html.cut\n"
      end
    end
  end
end

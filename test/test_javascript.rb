# encoding: UTF-8

require 'v8'
require 'spontaneous/rack'

module JavascriptTestBase

  def spontaneous_index
    V8::Context.new
  end

  def page
    config = mock()
    config.stubs(:reload_classes).returns(false)
    Spontaneous.stubs(:config).returns(config)
    page = V8::Context.new
    page.load(File.expand_path('../javascript/env.js', __FILE__))
    page.eval("window.console = {'log': function(){ print.apply(window, arguments)}, 'dir': function() {}};")
    page.eval("Spontaneous = {};")
    %w(JQUERY COMPATIBILITY EDITING_JS).each do |const|
      Spontaneous::Rack::Assets::JavaScript.const_get(const).each do |script|
        page.load(javascript_dir / "#{script}.js") unless ["load", "init"].include?(script)
      end
    end
    page.eval("jQuery.noConflict();")
    page
  end

  def javascript_dir
    File.expand_path("../../application/js", __FILE__)
  end

end


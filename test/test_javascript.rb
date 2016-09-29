# encoding: UTF-8

require 'execjs'
require 'spontaneous/rack'

module JavascriptTestBase

  def spontaneous_index
    V8::Context.new
  end

  def page
    config = mock()
    config.stubs(:reload_classes).returns(false)
    Spontaneous.stubs(:config).returns(config)
    source = File.read(File.expand_path('../javascript/env.js', __FILE__))
    context = ExecJS.compile(source)
    context.eval("window.console = {'log': function(){ print.apply(window, arguments)}, 'dir': function() {}};")
    context.eval("Spontaneous = {};")
    %w(JQUERY COMPATIBILITY EDITING_JS).each do |const|
      Spontaneous::Rack::Assets::JavaScript.const_get(const).each do |script|
        unless ["load", "init"].include?(script)
          context.eval(File.read(javascript_dir / "#{script}.js"))
        end
      end
    end
    context.eval("jQuery.noConflict();")
    context
  end

  def javascript_dir
    File.expand_path("../../application/js", __FILE__)
  end

end


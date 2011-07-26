# encoding: UTF-8

require 'harmony'

module JavascriptTestBase

  def spontaneous_index
    Harmony::Page.new
  end

  def page
    config = mock()
    config.stubs(:reload_classes).returns(false)
    Spontaneous.stubs(:config).returns(config)
    page = Harmony::Page.new
    page.x("window.console = {'log': function(){ print.apply(window, arguments)}, 'dir': function() {}};")
    page.x("Spontaneous = {};")
    Spontaneous::Rack::Back::JAVASCRIPT_FILES.each do |script|
      # jquery 1.5.1 doesn't work with johnson
      script = script.gsub(/jquery-1\.5\.1/, 'jquery-1.4.2')
      # puts script
      page.load(javascript_dir / "#{script}.js")
    end
    page.x("jQuery.noConflict();")
    # page.load(javascript_dir / 'properties.js')
    page
  end

  def javascript_dir
    "application/js"
  end

end


# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

require 'cgi'

describe "Templates" do
  def first_pass(base_dir, filename, context=nil)
    render_with_renderer(Cutaneous::PublishRenderer, base_dir, filename, context)
  end

  def second_pass(base_dir, filename, context=nil)
    render_with_renderer(Cutaneous::RequestRenderer, base_dir, filename, context)
  end

  def render_with_renderer(renderer_class, base_dir, filename, context = nil)
    context ||= @context
    renderer = renderer_class.new(make_template_root(base_dir))
    path = template_root / filename
    renderer.render(path, context)
  end

  def make_template_root(base_dir = "")
    @template_root = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/templates', base_dir))
    @site.paths.add(:templates, @template_root)
    @template_root
  end

  before do
    @site = setup_site
    make_template_root
    @klass = Class.new(Spontaneous::Output.context_class) do
      include Spontaneous::Output::Context::ContextCore
      include Spontaneous::Output::Context::PreviewContext

      def escape(val)
        ::CGI.escapeHTML(val)
      end
      def title
        "THE TITLE"
      end

      def unsafe
        "<script>alert('bad')</script>"
      end

      def bell
        'ding'
      end

      def show_errors?
        true
      end
    end
    @context = @klass.new(Object.new, :html)
  end

  after do
    teardown_site
  end

  describe "First render" do
    before do
      # @template = Cutaneous::PublishTemplate.new
      @engine = S::Output::Template::PublishEngine.new(@template_root)
    end

    it "ignore second level statements" do
      input = '<html><title>{{title}}</title>{{unsafe}}</html>'
      output = @engine.render_string(input, @context)
      output.must_equal  '<html><title>{{title}}</title>{{unsafe}}</html>'
    end

    it "evaluate first level expressions" do
      output = @engine.render_string('<html><title>${title}</title>{{unsafe}}</html>', @context)
      output.must_equal '<html><title>THE TITLE</title>{{unsafe}}</html>'
    end

    it "evaluate first level statements" do
      output = @engine.render_string('<html><title>${title}</title>%{ 2.times do }{{unsafe}}%{ end }</html>', @context)
      output.must_equal '<html><title>THE TITLE</title>{{unsafe}}{{unsafe}}</html>'
    end

    it "generate 2nd render templates" do
      output = @engine.render_string("<html><title>${title}</title>%{ 2.times do }{{bell}}\n%{ end }</html>", @context)
      second = S::Output::Template::RequestEngine.new(@template_root)
      output = second.render_string(output, @context)
      output.must_equal "<html><title>THE TITLE</title>ding\nding\n</html>"
    end

    it "handle multiline statements" do
      output = @engine.render_string((<<-TEMPLATE), @context)
%{
 something = 3
 nothing = 4; another = 5
-}
${ something + nothing + another -}
      TEMPLATE
      output.must_equal "12"
    end

    it "correctly handle braces within statements" do
      output = @engine.render_string((<<-TEMPLATE), @context)
%{
	a = { :a => "a", :b => "b" }
	b = { :c => "c", :d => "d" }
	c = a.map { |k, v| "\#{k}-\#{v}"}.join("/")
-}
${ a[:a] }${ a[:b] -}
      TEMPLATE
      output.must_equal "ab"
    end

    it "can convert a first-pass template to a second-pass template xxx" do
      input = "${ template 'content/template' }"
      output = @engine.render_string(input, @context)
      output.must_equal "<html><title>{{{ title }}}</title></html>\n"
    end
  end

  describe "Second render" do
    before do
      @engine = S::Output::Template::RequestEngine.new(@template_root)
    end

    it "a render unescaped expressions" do
      output = @engine.render_string('<html><title>{{title}}</title>{{{unsafe}}}</html>', @context)
      output.must_equal "<html><title>THE TITLE</title><script>alert('bad')</script></html>"
    end

    it "render escaped expressions" do
      output = @engine.render_string('<html><title>{{ unsafe }}</title></html>', @context)
      output.must_equal "<html><title>#{ERB::Util.html_escape(@context.unsafe)}</title></html>"
    end

    it "evaluate expressions" do
      output = @engine.render_string('<html>{% 2.times do %}<title>{{title}}</title>{% end %}</html>', @context)
      output.must_equal "<html><title>THE TITLE</title><title>THE TITLE</title></html>"
    end
  end

  describe "Content" do
    before do
      @engine = S::Output::Template::PublishEngine.new(@template_root / "content")
    end

    it "render" do
      output = @engine.render_template('template', @context)
      output.must_equal "<html><title>THE TITLE</title></html>\n"
    end

    it "preprocess" do
      output = @engine.render_template('preprocess', @context)
      output.must_equal "<html><title>THE TITLE</title>{{bell}}</html>\n"
    end

    it "include imports" do
      output = @engine.render_template('include', @context)
      output.must_equal "<html>{{bell}}ding\n</html>\n"
    end

    it "include imports in sub-directories" do
      output = @engine.render_template('include_dir', @context)
      output.must_equal "<html>{{ bell }}ding\n</html>\n"
    end

    it "preserve the format across includes" do
      context = @klass.new(Object.new)
      output = @engine.render_template('template', @context, "epub")
      output.must_equal "<epub><epub>{{ bell }}ding</epub>\n</epub>\n"
    end

    it "render a second pass" do
      engine = S::Output::Template::RequestEngine.new(@template_root / "content")
      output = engine.render_template('second', @context)
      output.must_equal "<html><title>THE TITLE</title>ding</html>\n"
    end

  end

  describe "hierarchy" do

    before do
      @engine = S::Output::Template::PublishEngine.new(@template_root / "extended")
    end

    it "work" do
      output = @engine.render_template('main', @context)
      expected = "Main Title {{page.title}}Grandparent Nav\nMain Body\nParent Body\nGrandparent Body\nGrandparent Footer\nParent Footer\n"
      output.must_equal expected
    end

    it "allow the use of includes" do
      output = @engine.render_template('with_includes', @context)
      output.must_equal (<<-RENDER)
Parent Title
INCLUDE
PARTIAL
Grandparent Footer
Parent Footer
      RENDER
    end

    it "allow passing of local variables to included templates" do
      output = @engine.render_template('with_includes_and_locals', @context)
      output.must_equal (<<-RENDER)
Parent Title
INCLUDE
local title
Grandparent Footer
Parent Footer
      RENDER
    end

    it "keeps a reference to the render cache in included templates" do
      # The render cache is kept on the renderer so it needs to be passed by the
      # context#clone method
      @context._renderer = "renderer"

      output = @engine.render_template('with_includes_and_renderer', @context)
      output.must_equal "renderer\nrenderer\n"
    end
  end

  describe "conversion" do
    before do

      @context_class = Class.new(Spontaneous::Output.context_class) do
        include Spontaneous::Output::Context::ContextCore
        include Spontaneous::Output::Context::PreviewContext

        def escape(val)
          CGI.escapeHTML(val)
        end

        def monkey
          "magic"
        end

        def field
          @klass ||= Class.new(Object) do
            attr_accessor :_format
            def to_html
              "(#{_format})"
            end

            def to_s
              "'#{_format}'"
            end
          end
          @klass.new.tap { |i| i._format = __format }
        end

        def slot
          @klass ||= Class.new(Object) do
            def render(format, *args)
              "(#{format})"
            end
          end
          @klass.new
        end
      end
      @engine = S::Output::Template::PublishEngine.new(@template_root)
      @context = @context_class.new(Object.new)
    end

    it "call #render(format) if context responds to it" do
      output = @engine.render_string('${slot} ${ monkey }', @context)
      output.must_equal "(html) magic"
    end

    it "call to_format on non-strings" do
      output = @engine.render_string('${field} ${ monkey }', @context)
      output.must_equal "(html) magic"
    end

    it "call to_s on non-strings that have no specific handler" do
      @context = @context_class.new(Object.new)
      output = @engine.render_string('${field} ${ monkey }', @context, "weird")
      output.must_equal "'weird' magic"
    end
  end
end

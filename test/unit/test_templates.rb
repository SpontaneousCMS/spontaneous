# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

require 'cgi'

class TemplatesTest < MiniTest::Spec
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

  def setup
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

  def teardown
    teardown_site
  end

  context "First render" do
    setup do
      # @template = Cutaneous::PublishTemplate.new
      @engine = S::Output::Template::PublishEngine.new(@template_root)
    end

    should "ignore second level statements" do
      input = '<html><title>{{title}}</title>{{unsafe}}</html>'
      output = @engine.render_string(input, @context)
      output.should ==  '<html><title>{{title}}</title>{{unsafe}}</html>'
    end

    should "evaluate first level expressions" do
      output = @engine.render_string('<html><title>${title}</title>{{unsafe}}</html>', @context)
      output.should == '<html><title>THE TITLE</title>{{unsafe}}</html>'
    end

    should "evaluate first level statements" do
      output = @engine.render_string('<html><title>${title}</title>%{ 2.times do }{{unsafe}}%{ end }</html>', @context)
      output.should == '<html><title>THE TITLE</title>{{unsafe}}{{unsafe}}</html>'
    end

    should "generate 2nd render templates" do
      output = @engine.render_string("<html><title>${title}</title>%{ 2.times do }{{bell}}\n%{ end }</html>", @context)
      second = S::Output::Template::RequestEngine.new(@template_root)
      output = second.render_string(output, @context)
      output.should == "<html><title>THE TITLE</title>ding\nding\n</html>"
    end

    should "handle multiline statements" do
      output = @engine.render_string((<<-TEMPLATE), @context)
%{
 something = 3
 nothing = 4; another = 5
-}
${ something + nothing + another -}
      TEMPLATE
      output.should == "12"
    end

    should "correctly handle braces within statements" do
      output = @engine.render_string((<<-TEMPLATE), @context)
%{
	a = { :a => "a", :b => "b" }
	b = { :c => "c", :d => "d" }
	c = a.map { |k, v| "\#{k}-\#{v}"}.join("/")
-}
${ a[:a] }${ a[:b] -}
      TEMPLATE
      output.should == "ab"
    end
  end

  context "Second render" do
    setup do
      @engine = S::Output::Template::RequestEngine.new(@template_root)
    end

    should "a render unescaped expressions" do
      output = @engine.render_string('<html><title>{{title}}</title>{{unsafe}}</html>', @context)
      output.should == "<html><title>THE TITLE</title><script>alert('bad')</script></html>"
    end

    should "render escaped expressions" do
      output = @engine.render_string('<html><title>{$ unsafe $}</title></html>', @context)
      output.should == "<html><title>&lt;script&gt;alert('bad')&lt;/script&gt;</title></html>"
    end

    should "evaluate expressions" do
      output = @engine.render_string('<html>{% 2.times do %}<title>{{title}}</title>{% end %}</html>', @context)
      output.should == "<html><title>THE TITLE</title><title>THE TITLE</title></html>"
    end
  end

  context "Content rendering" do
    setup do
      @engine = S::Output::Template::PublishEngine.new(@template_root / "content")
    end

    should "render" do
      output = @engine.render_template('template', @context)
      output.should == "<html><title>THE TITLE</title></html>\n"
    end

    should "preprocess" do
      output = @engine.render_template('preprocess', @context)
      output.should == "<html><title>THE TITLE</title>{{bell}}</html>\n"
    end

    should "include imports" do
      output = @engine.render_template('include', @context)
      output.should == "<html>{{bell}}ding\n</html>\n"
    end

    should "include imports in sub-directories" do
      output = @engine.render_template('include_dir', @context)
      output.should == "<html>{{ bell }}ding\n</html>\n"
    end

    should "preserve the format across includes" do
      context = @klass.new(Object.new)
      output = @engine.render_template('template', @context, "epub")
      output.should == "<epub><epub>{{ bell }}ding</epub>\n</epub>\n"
    end

    should "render a second pass" do
      engine = S::Output::Template::RequestEngine.new(@template_root / "content")
      output = engine.render_template('second', @context)
      output.should == "<html><title>THE TITLE</title>ding</html>\n"
    end

  end

  context "Template hierarchy" do

    setup do
      @engine = S::Output::Template::PublishEngine.new(@template_root / "extended")
    end

    should "work" do
      output = @engine.render_template('main', @context)
      expected = "Main Title {{page.title}}Grandparent Nav\nMain Body\nParent Body\nGrandparent Body\nGrandparent Footer\nParent Footer\n"
      output.should == expected
    end

    should "allow the use of includes" do
      output = @engine.render_template('with_includes', @context)
      output.should == (<<-RENDER)
Parent Title
INCLUDE
PARTIAL
Grandparent Footer
Parent Footer
      RENDER
    end

    should "allow passing of local variables to included templates" do
      output = @engine.render_template('with_includes_and_locals', @context)
      output.should == (<<-RENDER)
Parent Title
INCLUDE
local title
Grandparent Footer
Parent Footer
      RENDER
    end
  end

  context "Output conversion xxx" do
    setup do

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

    should "call #render(format) if context responds to it" do
      output = @engine.render_string('${slot} ${ monkey }', @context)
      output.should == "(html) magic"
    end

    should "call to_format on non-strings" do
      output = @engine.render_string('${field} ${ monkey }', @context)
      output.should == "(html) magic"
    end

    should "call to_s on non-strings that have no specific handler" do
      @context = @context_class.new(Object.new)
      output = @engine.render_string('${field} ${ monkey }', @context, "weird")
      output.should == "'weird' magic"
    end
  end
end

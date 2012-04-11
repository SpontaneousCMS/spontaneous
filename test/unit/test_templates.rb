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

  def make_template_root(base_dir)
    @template_root = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/templates', base_dir))
    @site.paths.add(:templates, @template_root)
    @template_root
  end

  def setup
    @site = setup_site
    @klass = Class.new(Object) do
      include Cutaneous::ContextHelper
      include Spontaneous::Render::PreviewContext

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
    @context = @klass.new(nil, :html)
  end

  def teardown
    teardown_site
  end

  context "First render" do
    setup do
      @template = Cutaneous::PublishTemplate.new
    end

    should "ignore second level statements" do
      input = '<html><title>{{title}}</title>{{unsafe}}</html>'
      @template.convert(input)
      output = @template.render(@context)
      output.should ==  '<html><title>{{title}}</title>{{unsafe}}</html>'
    end

    should "evaluate first level expressions" do
      @template.convert('<html><title>${title}</title>{{unsafe}}</html>')
      output = @template.render(@context)
      output.should == '<html><title>THE TITLE</title>{{unsafe}}</html>'
    end

    should "evaluate first level statements" do
      @template.convert('<html><title>${title}</title>%{ 2.times do }{{unsafe}}%{ end }</html>')
      output = @template.render(@context)
      output.should == '<html><title>THE TITLE</title>{{unsafe}}{{unsafe}}</html>'
    end

    should "generate 2nd render templates" do
      @template.convert("<html><title>${title}</title>%{ 2.times do }{{bell}}\n%{ end }</html>")
      output = @template.render(@context)
      second = Cutaneous::RequestTemplate.new
      second.convert(output)
      output = second.render(@context)
      output.should == "<html><title>THE TITLE</title>ding\nding\n</html>"
    end
  end

  context "Second render" do
    setup do
      @template = Cutaneous::RequestTemplate.new
    end

    should "a render unescaped expressions" do
      @template.convert('<html><title>{{title}}</title>{{unsafe}}</html>')
      output = @template.render(@context)
      output.should == "<html><title>THE TITLE</title><script>alert('bad')</script></html>"
    end

    should "render escaped expressions" do
      @template.convert('<html><title>{$ unsafe $}</title></html>')
      output = @template.render(@context)
      output.should == "<html><title>&lt;script&gt;alert('bad')&lt;/script&gt;</title></html>"
    end

    should "evaluate expressions" do
      @template.convert('<html>{% 2.times do %}<title>{{title}}</title>{% end %}</html>')
      output = @template.render(@context)
      output.should == "<html><title>THE TITLE</title><title>THE TITLE</title></html>"
    end
  end

  context "Content rendering" do
    should "render" do
      output = first_pass('content', 'template')
      output.should == "<html><title>THE TITLE</title></html>\n"
    end

    should "preprocess" do
      output = first_pass('content', 'preprocess')
      output.should == "<html><title>THE TITLE</title>{{bell}}</html>\n"
    end

    should "include imports" do
      output = first_pass('content', 'include')
      output.should == "<html>{{bell}}ding\n</html>\n"
    end

    should "include imports in sub-directories" do
      output = first_pass('content', 'include_dir')
      output.should == "<html>{{ bell }}ding\n</html>\n"
    end

    should "preserve the format across includes" do
      context = @klass.new(nil, :epub)
      context.format.should == :epub
      output = first_pass('content', 'template', context)
      output.should == "<epub><epub>{{ bell }}ding</epub>\n</epub>\n"
    end

    should "render a second pass" do
      output = second_pass('content', 'second')
      output.should == "<html><title>THE TITLE</title>ding</html>\n"
    end

  end

  context "Template hierarchy" do

    setup do
    end

    should "work" do
      output = first_pass('extended', 'main')
      output.should == "Main Title {{page.title}}Grandparent Nav\nMain Body\nParent Body\nGrandparent Body\nGrandparent Footer\nParent Footer\n"
    end

    should "allow the use of includes" do
      output = first_pass('extended', 'with_includes')
      output.should == (<<-RENDER)
Parent Title
INCLUDE
PARTIAL
Grandparent Footer
Parent Footer
      RENDER
    end

    should "allow passing of local variables to included templates" do
      output = first_pass('extended', 'with_includes_and_locals')
      output.should == (<<-RENDER)
Parent Title
INCLUDE
local title
Grandparent Footer
Parent Footer
      RENDER
    end
    should "handle multiline statements" do
      output = first_pass('engine', 'multiline')
      output.should == "12\n"
    end

    should "correctly handle braces within statements" do
      output = first_pass('engine', 'braces')
      output.should == "ab\n"
    end
  end

  context "Output conversion" do
    setup do

      @context_class = Class.new(Object) do
        include Cutaneous::ContextHelper
        include Spontaneous::Render::PreviewContext

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
          @klass.new.tap { |i| i._format = _format }
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
      @template = Cutaneous::PublishTemplate.new
    end

    should "call #render(format) if context responds to it" do
      context = @context_class.new(nil, :html)
      @template.convert('${slot} ${ monkey }')
      output = @template.render(context)
      output.should == "(html) magic"
    end

    should "call to_format on non-strings" do
      context = @context_class.new(nil, :html)
      @template.convert('${field} ${ monkey }')
      output = @template.render(context)
      output.should == "(html) magic"
    end

    should "call to_s on non-strings that have no specific handler" do
      context = @context_class.new(nil, :weird)
      @template.convert('${field} ${ monkey }')
      output = @template.render(context)
      output.should == "'weird' magic"
    end
  end
end

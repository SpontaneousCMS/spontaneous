# encoding: UTF-8

require 'test_helper'


class TemplatesTest < Test::Unit::TestCase

  def setup
    @klass = Class.new(Object) do
      include Cutaneous::ContextHelper
      ## this
      def escape(val)
        CGI.escapeHTML(val)
      end
      def title
        "THE TITLE"
      end

      def unsafe
        "<script>alert('bad')</script>"
      end
    end
    @context = @klass.new
  end

  context "First render" do
    setup do
      @template = Cutaneous::Preprocessor.new
    end

    should "ignore second level statements" do
      input = '<html><title>#{title}</title>#{unsafe}</html>'
      @template.convert(input)
      output = @template.render(@context)
      output.should ==  '<html><title>#{title}</title>#{unsafe}</html>'
    end

    should "evaluate first level expressions" do
      @template.convert('<html><title>{{title}}</title>#{unsafe}</html>')
      output = @template.render(@context)
      output.should == '<html><title>THE TITLE</title>#{unsafe}</html>'
    end

    should "evaluate first level statements" do
      @template.convert("<html><title>{{title}}</title>{% 2.times do %}\#{unsafe}{% end %}</html>")
      output = @template.render(@context)
      output.should == '<html><title>THE TITLE</title>#{unsafe}#{unsafe}</html>'
    end
  end

  context "Second render" do
    setup do
      @template = Cutaneous::Template.new
    end

    should "a render unescaped expressions" do
      @template.convert('<html><title>#{title}</title>#{unsafe}</html>')
      output = @template.render(@context)
      output.should == "<html><title>THE TITLE</title><script>alert('bad')</script></html>"
    end

    should "render escaped expressions" do
      @template.convert('<html><title>${unsafe}</title></html>')
      output = @template.render(@context)
      output.should == "<html><title>&lt;script&gt;alert('bad')&lt;/script&gt;</title></html>"
    end

    should "evaluate expressions" do
      @template.convert('<html>%{ 2.times do }<title>#{title}</title>%{ end }</html>')
      output = @template.render(@context)
      output.should == "<html><title>THE TITLE</title><title>THE TITLE</title></html>"
    end
  end
end

require 'test_helper'


class TemplatesTest < Test::Unit::TestCase
  include Spontaneous

  def template_root
    @template_root ||= File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/templates"))
  end

  context "template root" do
    should "be settable" do
      File.exists?(template_root).should be_true
      Spontaneous.template_root = template_root
      Spontaneous.template_root.should == template_root
    end
  end

  context "template class" do
    setup do
      Spontaneous.template_root = template_root
      class ::TemplateClass; end
      @name = :this_template
      @template = Template.new(TemplateClass.new, @name)
    end

    teardown do
      Object.send(:remove_const, :TemplateClass)
    end

    should "derive path from owning class and name" do
      @template.directory.should == "#{template_root}/template_class"
    end

    should "derive template filename from given name & format" do
      @template.filename.should == "this_template.html.erb"
      @template.filename(:pdf).should == "this_template.pdf.erb"
    end

    should "have correct path for template file" do
      @template.path(:html).should == "#{template_root}/template_class/this_template.html.erb"
    end

    should "be able to give a list of available formats" do
      @template.formats.should == [:epub, :html, :pdf]
    end

    context "inline templates" do
      setup do
        @class = Class.new(Content)
      end
      should "be definiable" do
        @class.inline_style :simple
        @class.inline_styles.length.should == 1
        t = @class.inline_styles.first
        t.name.should == :simple
      end

      should "have configurable filenames" do
        @class.inline_style :simple, :filename => "funky"
        t = @class.inline_styles.first
        t.filename.should == "funky.html.erb"
      end

      should "have sane default titles" do
        @class.inline_style :simple_style
        t = @class.inline_styles.first
        t.title.should == "Simple Style"
      end

      should "have configurable titles" do
        @class.inline_style :simple, :title => "A Simple Style"
        t = @class.inline_styles.first
        t.title.should == "A Simple Style"
      end

      should "be accessable by name" do
        @class.inline_style :simple
        @class.inline_style :complex
        @class.inline_styles[:simple].should == @class.inline_styles.first
      end

      should "have #styles as a shortcut for #inliine_styles" do
        @class.inline_style :simple
        @class.inline_styles.should == @class.styles
      end

      should "take the first style as the default" do
        @class.inline_style :simple
        @class.inline_style :complex
        @class.styles.default.should == @class.styles[:simple]
      end

      should "honour the :default flag" do
        @class.inline_style :simple
        @class.inline_style :complex, :default => true
        @class.styles.default.should == @class.styles[:complex]
      end
    end
  end
end

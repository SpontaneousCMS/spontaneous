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
        @class.inline_template :simple
        @class.inline_templates.length.should == 1
      end
    end
  end
end

# encoding: UTF-8

require 'test_helper'


class StylesTest < Test::Unit::TestCase
  include Spontaneous

  def template_root
    @style_root ||= File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/templates"))
  end

  context "template root" do
    should "be settable" do
      File.exists?(template_root).should be_true
      Spontaneous.template_root = template_root
      Spontaneous.template_root.should == template_root
    end
  end

  context "style class" do
    setup do
      Spontaneous.template_root = template_root
      class ::TemplateClass; end
      @name = :this_template
      @style = Style.new(TemplateClass, @name)
    end

    teardown do
      Object.send(:remove_const, :TemplateClass)
    end

    should "derive path from owning class and name" do
      @style.directory.should == "template_class"
    end

    should "derive template filename from given name & format" do
      @style.filename.should == "this_template.html.cut"
      @style.filename(:pdf).should == "this_template.pdf.cut"
    end

    should "have correct path for template file" do
      @style.path(:html).should == "template_class/this_template"
    end

    should "be able to give a list of available formats" do
      @style.formats.should == [:epub, :html, :pdf]
    end

    # should "return a template for a given format" do
    #   template = @style.template(:pdf)
    #   template.filename.should == "this_template.pdf.cut"
    #   template.path.should == "#{template_root}/template_class/this_template.pdf.cut"
    # end


    should "raise an error if we try to initialize with an unsupported format" do
      # disabled because it makes testing styles more difficult
      # perhaps raise this instead at the template level when rendering?
      # lambda { @style.template(:monkey) }.should raise_error(UnsupportedFormatException)
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
        t.filename.should == "funky.html.cut"
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

    context "assigned styles" do
      setup do
        class ::StyleTestClass < Content
          inline_style :first_style
          inline_style :default_style, :default => true
        end

        @a = StyleTestClass.new
        @b = StyleTestClass.new
        @a << @b
      end

      teardown do
        Object.send(:remove_const, :StyleTestClass)
      end

      should "assign the default style" do
        @a.entries.first.style.should == ::StyleTestClass.styles.default
      end

      should "persist" do
        @a.save
        @b.save
        @a = StyleTestClass[@a.id]
        @a.entries.first.style.should == ::StyleTestClass.styles.default
      end

      should "be settable" do
        @a.entries.first.style = StyleTestClass.styles[:first_style]
        @a.save
        @a = StyleTestClass[@a.id]
        @a.entries.first.style.should == ::StyleTestClass.styles[:first_style]
      end

      context "direct facet access" do
        setup do
          @a.entries.first.style = StyleTestClass.styles[:first_style]
          @a.save
          facet_id = @a.entries.first.target.id
          @facet = StyleTestClass[facet_id]
        end

        should "be accessible directly for facets" do
          @facet.style.should == ::StyleTestClass.styles[:first_style]
        end

        should "not be settable directly on bare facets" do
          lambda { @facet.style = ::StyleTestClass.styles.default }.should raise_error(NoMethodError)
        end
      end
    end

    context "inline templates" do
      setup do
        class ::InlineTemplateClass < Content
          field :title

          template 'title: {{title}}'
        end

        @a = InlineTemplateClass.new
        @a.title = "Total Title"
      end

      teardown do
        Object.send(:remove_const, :InlineTemplateClass)
      end

      should "be used to render the content" do
        @a.render.should ==  "title: Total Title"
      end
    end

    context "default styles" do
      setup do
        class ::DefaultStyleClass < Content
          field :title
        end
        class ::WithoutDefaultStyleClass < Content
          field :title
          slot :with_style, :type => :DefaultStyleClass
        end

        @with_default_style = DefaultStyleClass.new
        @with_default_style.title = "Total Title"
        @without_default_style = WithoutDefaultStyleClass.new
        @without_default_style.title = "No Title"
        @without_default_style.with_style.title = "Slot Title"
      end

      teardown do
        Object.send(:remove_const, :DefaultStyleClass)
        Object.send(:remove_const, :WithoutDefaultStyleClass)
      end

      should "be used when available" do
        @with_default_style.render.should == "Title: Total Title\n"
      end

      should "be used by slots too" do
        @without_default_style.with_style.render.should == "Title: Slot Title\n"
      end

      should "fallback to anonymous style when default style template doesn't exist" do
        @without_default_style.render.should == "Title: Slot Title\n"
      end
    end
  end
end

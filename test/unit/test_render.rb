# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

require 'sinatra/base'

class RenderTest < MiniTest::Spec

  def setup
    @site = setup_site
    Content.delete
  end

  def teardown
    teardown_site
    Spontaneous::Output.cache_templates = false
  end

  def template_root
    @template_root ||= File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/templates"))
  end

  context "Publish rendering step" do
    setup do
      @site.paths.add(:templates, template_root)

      Page.field :title
      Page.box :sections1
      Page.box :sections2

      class ::TemplateClass < ::Piece
        field :title do
          def to_epub
            to_html
          end
        end
        field :description do
          def to_pdf
            "{#{value}}"
          end
          def to_epub
            to_html
          end
        end

        style :this_template
        style :another_template
      end

      @root = ::Page.create(:title => "Home")
      @page = ::Page.create(:title => "Page Title")

      @content = TemplateClass.new
      @content.style.should == TemplateClass.default_style
      @content.title = "The Title"
      @content.description = "The Description"

      @page.sections1 << @content

      @section1 = ::Page.new(:title => "Section 1")
      @section2 = ::Page.new(:title => "Section 2")
      @section3 = ::Page.new(:title => "Section 3")
      @section4 = ::Page.new(:title => "Section 4")
      @root.sections1 << @section1
      @root.sections1 << @section2
      @root.sections2 << @section3
      @root.sections2 << @section4

      @root.sections2.entries.last.set_position(0)
      @root.save.reload
      @renderer = Spontaneous::Output::Template::PublishRenderer.new
      Spontaneous::Output.renderer = @renderer
    end

    teardown do
      Object.send(:remove_const, :TemplateClass) rescue nil
      Object.send(:remove_const, :Page) rescue nil
    end

    should "render strings correctly" do
      @renderer.render_string('${title} {{ Time.now }}', @page.output(:html), {}).should == "Page Title {{ Time.now }}"
    end

    should "use a cache for the site root" do
        a = @renderer.render_string('#{root.object_id} #{root.object_id}', @page.output(:html), {})
        a.should_not == "#{nil.object_id} #{nil.object_id}"
        a.split.uniq.length.should == 1
    end

    should "iterate through the sections" do
      template = '%%{ navigation(%s) do |section, active| }${section.title}/${active} %%{ end }'
      a = @renderer.render_string(template % "", @section1.output(:html), {})
      a.should == "Section 1/true Section 2/false Section 4/false Section 3/false "
      a = @renderer.render_string(template % "1", @section2.output(:html), {})
      a.should == "Section 1/false Section 2/true Section 4/false Section 3/false "
      a = @renderer.render_string(template % ":section", @section1.output(:html), {})
      a.should == "Section 1/true Section 2/false Section 4/false Section 3/false "
    end

    should "use a cache for navigation pages" do
      a = b = c = nil
      template = '%{ navigation do |section, active| }${section.object_id} %{ end }'
      renderer = Spontaneous::Output::Template::PreviewRenderer.new
      a = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      b = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      a.should_not == b

      renderer = Spontaneous::Output::Template::PublishRenderer.new
      template = '%{ navigation do |section, active| }${section.object_id} %{ end }'
      a = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      b = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      a.should == b

      renderer = Spontaneous::Output::Template::PublishRenderer.new
      template = '%{ navigation do |section, active| }${section.object_id} %{ end }'
      c = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      a.should_not == c
    end

    should "be able to render themselves to HTML" do
      @content.render.should == "<html><title>The Title</title><body>The Description</body></html>\n"
    end

    should "be able to render themselves to PDF" do
      Page.add_output :pdf
      @content.render(:pdf).should == "<PDF><title>The Title</title><body>{The Description}</body></PDF>\n"
    end

    should "be able to render themselves to EPUB" do
      Page.add_output :epub
      @content.render(:epub).should == "<EPUB><title>The Title</title><body>The Description</body></EPUB>\n"
    end

    context "piece trees" do
      setup do
        @page = ::Page.create
        TemplateClass.style :complex_template, :default => true
        TemplateClass.box :bits
        @content = TemplateClass.new
        @page.sections1 << @content
        @content.title = "The Title"
        @content.description = "The Description"
        @child = TemplateClass.new
        @child.title = "Child Title"
        @child.description = "Child Description"
        @content.bits << @child
        @content.contents.first.style = TemplateClass.get_style(:this_template)
      end

      teardown do
        Content.delete
      end

      should "be accessible through #content method" do
        expected = "<complex>\nThe Title\n<piece><html><title>Child Title</title><body>Child Description</body></html>\n</piece>\n</complex>\n"
        @content.render.should == expected
      end

      should "cascade the chosen format to all subsequent #render calls" do
        ::Page.add_output :pdf
        @content.render(:pdf).should == "<pdf>\nThe Title\n<piece><PDF><title>Child Title</title><body>{Child Description}</body></PDF>\n</piece>\n</pdf>\n"
      end

      should "only show visible pieces" do
        child = TemplateClass.new
        child.title = "Child2 Title"
        child.description = "Child2 Description"
        @content.bits << child
        @content.bits.last.style = TemplateClass.get_style(:this_template)
        @content.bits.last.hide!

        expected = "<complex>\nThe Title\n<piece><html><title>Child Title</title><body>Child Description</body></html>\n</piece>\n</complex>\n"
        @content.render.should == expected
      end
    end

    context "boxes" do
      setup do
        TemplateClass.style :slots_template, :default => true
        TemplateClass.box :images
        @page = ::Page.new
        @content = TemplateClass.new
        @content.title = "The Title"
        @content.description = "The Description"
        @page.sections1 << @content
        @child = TemplateClass.new
        @child.title = "Child Title"
        @child.description = "Child Description"
        @content.images << @child
        @content.images.first.style = TemplateClass.get_style(:this_template)
      end

      should "render boxes" do
        @content.render.should == "<boxes>\n  <img><html><title>Child Title</title><body>Child Description</body></html>\n</img>\n</boxes>\n"
      end
      should "render boxes to alternate formats" do
        ::Page.add_output :pdf
        @content.render(:pdf).should == "<boxes-pdf>\n  <img><PDF><title>Child Title</title><body>{Child Description}</body></PDF>\n</img>\n</boxes-pdf>\n"
      end
    end

    context "anonymous boxes" do
      setup do
        TemplateClass.style :anonymous_style, :default => true
        TemplateClass.box :images do
          field :introduction
        end

        class ::AnImage < Content; end
        AnImage.field :title
        AnImage.template '<img>#{title}</img>'

        @page = ::Page.new
        @root = TemplateClass.new
        @page.sections1 << @root
        @root.images.introduction = "Images below:"
        @image1 = AnImage.new
        @image1.title = "Image 1"
        @image2 = AnImage.new
        @image2.title = "Image 2"
        @root.images << @image1
        @root.images << @image2

      end

      teardown do
        Object.send(:remove_const, :AnImage) rescue nil
      end

      should "render using anonymous style" do
        @root.render.should == "<root>\nImages below:\n<img>Image 1</img>\n<img>Image 2</img>\n</root>\n"
      end
    end

    context "default templates" do
      setup do
        TemplateClass.style :default_template_style, :default => true
        TemplateClass.box :images_with_template do
          field :introduction
        end

        class ::AnImage < Content; end
        AnImage.field :title
        AnImage.template '<img>#{title}</img>'

        @page = ::Page.create
        @root = TemplateClass.new
        @page.sections1 << @root
        @root.images_with_template.introduction = "Images below:"
        @image1 = AnImage.new
        @image1.title = "Image 1"
        @image2 = AnImage.new
        @image2.title = "Image 2"
        @root.images_with_template << @image1
        @root.images_with_template << @image2
      end

      teardown do
        Object.send(:remove_const, :AnImage) rescue nil
      end

      should "render using default style if present" do
        @root.render.should == "<root>\nImages below:\n<images>\n  <img>Image 1</img>\n  <img>Image 2</img>\n</images>\n</root>\n"
      end
    end

    context "page styles" do
      setup do
        class ::PageClass < Page
          field :title, :string
        end
        PageClass.layout :subdir_style
        PageClass.layout :standard_page
        @parent = PageClass.new
        @parent.title = "Parent"
      end

      teardown do
        Object.send(:remove_const, :PageClass) rescue nil
      end

      should "find page styles at root of templates dir" do
        @parent.layout = :standard_page
        @parent.render.should == "/Parent/\n"
      end

      should "find page styles in class sub dir" do
        @parent.layout = :subdir_style
        @parent.render.should == "<Parent>\n"
      end
    end

    context "pages as inline content" do

      setup do
        class ::PageClass < Page
          field :title, :string
        end
        PageClass.box :things
        PageClass.layout :page_style
        PageClass.style :inline_style
        @parent = PageClass.new
        @parent.title = "Parent"
        @page = PageClass.new
        @page.title = "Child"
        @parent.things << @page
        @parent.save
        @page.save
      end

      teardown do
        Object.send(:remove_const, :PageClass) rescue nil
      end

      should "use style assigned by entry" do
        @parent.contents.first.style.should == PageClass.default_style
        @parent.things.first.style.should == PageClass.default_style
      end

      should "use their default page style when accessed directly" do
        @page = PageClass[@page.id]
        @page.layout.should == PageClass.default_layout
        assert_correct_template(@parent, template_root / 'layouts/page_style')
        @page.render.should == "<html></html>\n"
      end

      should "persist sub-page style settings" do
        @parent = Content[@parent.id]
        @parent.contents.first.style.should == PageClass.default_style
      end

      should "render using the inline style" do
        assert_correct_template(@parent.contents.first, template_root / 'page_class/inline_style')
        @parent.contents.first.render.should == "Child\n"
        @parent.things.render.should == "Child\n"
        @parent.render.should == "<html>Child\n</html>\n"
      end
    end

    context "params in templates" do
      setup do
        class ::TemplateParams < Page; end
        TemplateParams.field :image, :default => "/images/fromage.jpg"
        TemplateParams.layout :template_params
        @page = TemplateParams.new
      end
      teardown do
        Object.send(:remove_const, :TemplateParams) rescue nil
      end
      should "be passed to the render call" do
        @page.image.value.should == "/images/fromage.jpg"
        @page.image.src.should == "/images/fromage.jpg"
        @page.render.should =~ /alt="Smelly"/
      end
    end
  end

  context "Request rendering" do
    setup do
      @site.paths.add(:templates, template_root)

      class ::PreviewRender < Page
        field :title, :string
      end
      PreviewRender.style :inline
      PreviewRender.box :images
      PreviewRender.field :description, :markdown
      @page = PreviewRender.new(:title => "PAGE", :description => "DESCRIPTION")
      @page.save
      @session = ::Rack::MockSession.new(::Sinatra::Application)
    end

    teardown do
      Object.send(:remove_const, :PreviewRender)
    end

    context "Preview render" do
      setup do
        @renderer = Spontaneous::Output::Template::PreviewRenderer.new
        Spontaneous::Output.renderer = @renderer
        PreviewRender.layout :preview_render
      end

      should "output both publish & request tags" do
        @now = Time.now
        ::Time.stubs(:now).returns(@now)
        @renderer.render_string('${title} {{ Time.now }}', @page.output(:html), {}).should == "PAGE #{@now.to_s}"
      end

#       should "render all tags & include preview edit markers" do
#         @page.render.should == <<-HTML
# PAGE <p>DESCRIPTION</p>
#
# <!-- spontaneous:previewedit:start:box id:#{@page.images.schema_id} -->
# <!-- spontaneous:previewedit:end:box id:#{@page.images.schema_id} -->
#
#         HTML
#       end
    end
    context "Request rendering" do
      setup do
        @renderer = Spontaneous::Output::Template::PreviewRenderer.new
        Spontaneous::Output.renderer = @renderer
        PreviewRender.layout :params
      end

      should "pass on passed params" do
        result = @page.render({
          :welcome => "hello"
        })
        result.should == "PAGE hello\n"
      end
    end


    context "entry parameters" do
      setup do
        @renderer = Spontaneous::Output::Template::PreviewRenderer.new
        Spontaneous::Output.renderer = @renderer
        PreviewRender.layout :entries
        @first = PreviewRender.new(:title => "first")
        @second = PreviewRender.new(:title => "second")
        @third = PreviewRender.new(:title => "third")
        @page.images << @first
        @page.images << @second
        @page.images << @third
        @page.save
      end
      should "be available to templates" do
        @page.render.should == "0>first\n1second\n2<third\n0:first\n1:second\n2:third\nfirst.second.third\n"
      end
    end

    context "Publishing renderer" do
      setup do
        Spontaneous::Output.write_compiled_scripts = true
        @temp_template_root = @site.root / "templates"
        FileUtils.mkdir_p(@temp_template_root)
        FileUtils.mkdir_p(@temp_template_root / "layouts")
        @site.paths.add(:templates, @temp_template_root)

        @renderer = Spontaneous::Output::Template::PublishRenderer.new(true)
        Spontaneous::Output.renderer = @renderer

        @template_path = @temp_template_root / "layouts/standard.html.cut"
        @compiled_path = @temp_template_root / "layouts/standard.html.rb"
        File.open(@template_path, "w") do |t|
          t.write("template")
        end
        File.open(@compiled_path, "w") do |t|
          t.write("@__buf << 'compiled'")
        end
        later = Time.now + 10
        File.utime(later, later, @compiled_path)
        template_mtime = File.mtime(@template_path)
        compiled_mtime = File.mtime(@compiled_path)
        assert compiled_mtime > template_mtime, "Compiled file should register as newer"
        @first = PreviewRender.new(:title => "first")
        @first.save
      end

      should "ignore compiled template file if it is older than the template" do
        @first.render.should == "compiled"
        File.open(@temp_template_root / "layouts/standard.html.cut", "w") do |t|
          t.write("updated template")
        end
        later = Time.now + 1000
        File.utime(later, later, @template_path)
        template_mtime = File.mtime(@template_path)
        compiled_mtime = File.mtime(@compiled_path)
        assert template_mtime > compiled_mtime, "Template file should register as newer"
        # Need to use a new renderer because the existing one will have cached the compiled template
        @renderer = Spontaneous::Output::Template::PublishRenderer.new
        Spontaneous::Output.renderer = @renderer
        @first.render.should == "updated template"
      end
    end

    context "variables in render command" do
      setup do
        @renderer = Spontaneous::Output::Template::PublishRenderer.new
        Spontaneous::Output.renderer = @renderer

        PreviewRender.layout :variables
        PreviewRender.style :variables

        @page.layout = :variables
        @first = PreviewRender.new(:title => "first")
        @page.images << @first
        @page.images.first.style = :variables
      end

      should "be passed to page content" do
        @page.render(:html, :param => "param").should == "param\n<variable/param/>\n\nlocal\n"
      end
    end
  end
end

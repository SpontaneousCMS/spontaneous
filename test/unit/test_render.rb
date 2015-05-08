# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

require 'sinatra/base'

describe "Render" do

  before do
    @site = setup_site
    Content.delete
  end

  after do
    teardown_site
    Spontaneous::Output.cache_templates = false
  end

  def template_root
    @template_root ||= File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/templates"))
  end

  describe "Publish rendering step" do
    before do
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
          def render(format = :html, locals = {}, parent_context = nil)
            case format
            when :pdf
              to_pdf
            else
              super
            end
          end

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
      @content.style.must_equal TemplateClass.default_style
      @content.title = "The Title"
      @content.description = "The Description"

      @page.sections1 << @content

      @section1 = ::Page.new(:title => "Section 1", :uid => "section1")
      @section2 = ::Page.new(:title => "Section 2")
      @section3 = ::Page.new(:title => "Section 3")
      @section4 = ::Page.new(:title => "Section 4")
      @root.sections1 << @section1
      @root.sections1 << @section2
      @root.sections2 << @section3
      @root.sections2 << @section4
      @root.sections2.last.set_position(0)
      @root.save.reload
      @transaction = Spontaneous::Publishing::Transaction.new(@site, 99, nil)
      @renderer = Spontaneous::Output::Template::PublishRenderer.new(@transaction)
    end

    after do
      Object.send(:remove_const, :TemplateClass) rescue nil
      Object.send(:remove_const, :Page) rescue nil
    end

    it "render strings correctly" do
      @renderer.render_string('${title} {{ Time.now }}', @page.output(:html), {}).must_equal "Page Title {{ Time.now }}"
    end

    it "use a cache for the site root" do
      a = @renderer.render_string('#{root.object_id} #{root.object_id}', @page.output(:html), {})
      a.wont_equal "#{nil.object_id} #{nil.object_id}"
      a.split.uniq.length.must_equal 1
    end

    it "uses a cache for site pages" do
      a = @renderer.render_string("${site_page('$section1').object_id}", @page.output(:html), {})
      a.wont_equal "#{nil.object_id} #{nil.object_id}"
      b = @renderer.render_string("${site_page('$section1').object_id}", @page.output(:html), {})
      a.must_equal b
    end

    it "iterate through the sections" do
      template = '%%{ navigation(%s) do |section, active| }${section.title}/${active} %%{ end }'
      a = @renderer.render_string(template % "", @section1.output(:html), {})
      a.must_equal "Section 1/true Section 2/false Section 4/false Section 3/false "
      a = @renderer.render_string(template % "depth: 1", @section2.output(:html), {})
      a.must_equal "Section 1/false Section 2/true Section 4/false Section 3/false "
      a = @renderer.render_string(template % "depth: :section", @section1.output(:html), {})
      a.must_equal "Section 1/true Section 2/false Section 4/false Section 3/false "
    end

    it "use a cache for navigation pages" do
      a = b = c = nil
      template = '%{ navigation do |section, active| }${section.object_id} %{ end }'
      renderer = Spontaneous::Output::Template::PreviewRenderer.new(@site)
      a = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      b = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      a.wont_equal b

      renderer = Spontaneous::Output::Template::PublishRenderer.new(@transaction)
      template = '%{ navigation do |section, active| }${section.object_id} %{ end }'
      a = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      b = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      a.must_equal b

      renderer = Spontaneous::Output::Template::PublishRenderer.new(@transaction)
      template = '%{ navigation do |section, active| }${section.object_id} %{ end }'
      c = renderer.render_string(template, ::Content[@section1.id].output(:html), {}).strip
      a.wont_equal c
    end

    it "be able to render themselves to HTML" do
      @content.render.must_equal "<html><title>The Title</title><body>The Description</body></html>\n"
    end

    it "be able to render themselves to PDF" do
      Page.add_output :pdf
      @content.render(:pdf).must_equal "<PDF><title>The Title</title><body>{The Description}</body></PDF>\n"
    end

    it "be able to render themselves to EPUB" do
      Page.add_output :epub
      @content.render(:epub).must_equal "<EPUB><title>The Title</title><body>The Description</body></EPUB>\n"
    end

    it "can specify an alternate object as the content source" do
      class Page
        layout(:html) { "=${title}"}
      end
      class DivertedPage < Page
        layout(:html) { "!${title}"}
        renders { sections1.first }
      end
      parent = DivertedPage.create(title: "parent")
      child = Page.create(title: "child")
      @root.sections1 << parent
      @root.save
      parent.sections1 << child
      parent.save
      child.save
      expected = child.render(:html)
      parent.render(:html).must_equal expected
    end

    describe "piece trees" do
      before do
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
        @content.contents.first.update(style: TemplateClass.get_style(:this_template))
      end

      after do
        Content.delete
      end

      it "be accessible through #content method" do
        expected = "<complex>\nThe Title\n<piece><html><title>Child Title</title><body>Child Description</body></html>\n</piece>\n</complex>\n"
        @content.render.must_equal expected
      end

      it "cascade the chosen format to all subsequent #render calls" do
        ::Page.add_output :pdf
        @content.render(:pdf).must_equal "<pdf>\nThe Title\n<piece><PDF><title>Child Title</title><body>{Child Description}</body></PDF>\n</piece>\n</pdf>\n"
      end

      it "only show visible pieces" do
        child = TemplateClass.new
        child.title = "Child2 Title"
        child.description = "Child2 Description"
        @content.bits << child
        @content.bits.last.style = TemplateClass.get_style(:this_template)
        @content.bits.last.hide!

        expected = "<complex>\nThe Title\n<piece><html><title>Child Title</title><body>Child Description</body></html>\n</piece>\n</complex>\n"
        @content.render.must_equal expected
      end
    end

    describe "fields" do
      it "render a joined list of field values" do
        Page.field :description, :markdown
        Page.field :image
        ::Page.layout do
          %(${ fields })
        end
        @page.title = "Title & Things"
        @page.image = "/photo.jpg"
        @page.description = "Description & Stuff"
        lines = @page.render.split(/\n(?=<div)/)
        @page.fields.each_with_index do |field, i|
          lines[i].must_match /<div.+?>#{field.render(:html)}<\/div>/
        end
      end

      it "passes arguments onto the render" do
        Page.field :image do
          size :large do; end
          size :small do; end
        end
        Page.layout do
          %{${ image(width: 10, height: 50, alt: "Fish")}}
        end
        @page.image = "/photo.jpg"
        output =  @page.render
        output.must_match /width=['"]10['"]/
        output.must_match /height=['"]50['"]/
        output.must_match /alt=['"]Fish['"]/
      end

      it "passes arguments onto the render for image sizes" do
        Page.field :image do
          size :large do; end
          size :small do; end
        end
        Page.layout do
          %{${ image.large(width: 10, height: 50)}}
        end
        @page.image = "/photo.jpg"
        output =  @page.render
        output.must_match /width=['"]10["']/
        output.must_match /height=["']50['"]/
      end

    end
    describe "boxes" do
      before do
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
        @content.images.first.update(style: TemplateClass.get_style(:this_template))
        @content.save
      end

      it "render box sets as a joined list of each box's output" do
        ::Page.layout do
          %(${ content })
        end
        @page.render.must_equal @page.boxes.map(&:render).join("\n")
      end

      it "render 'boxes' as a joined list of each box's output" do
        ::Page.layout do
          %(${ boxes })
        end
        @page.render.must_equal @page.boxes.map(&:render).join("\n")
      end

      it "render boxes" do
        @content.render.must_equal "<boxes>\n  <img><html><title>Child Title</title><body>Child Description</body></html>\n</img>\n</boxes>\n"
      end

      it "render boxes to alternate formats" do
        ::Page.add_output :pdf
        @content.render(:pdf).must_equal "<boxes-pdf>\n  <img><PDF><title>Child Title</title><body>{Child Description}</body></PDF>\n</img>\n</boxes-pdf>\n"
      end
    end

    describe "anonymous boxes" do
      before do
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

      after do
        Object.send(:remove_const, :AnImage) rescue nil
      end

      it "render using anonymous style" do
        @root.render.must_equal "<root>\nImages below:\n<img>Image 1</img>\n<img>Image 2</img>\n</root>\n"
      end
    end

    describe "default templates" do
      before do
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

      after do
        Object.send(:remove_const, :AnImage) rescue nil
      end

      it "render using default style if present" do
        @root.render.must_equal "<root>\nImages below:\n<images>\n  <img>Image 1</img>\n  <img>Image 2</img>\n</images>\n</root>\n"
      end
    end

    describe "page styles" do
      before do
        class ::PageClass < Page
          field :title, :string
        end
        PageClass.layout :subdir_style
        PageClass.layout :standard_page
        @parent = PageClass.new
        @parent.title = "Parent"
      end

      after do
        Object.send(:remove_const, :PageClass) rescue nil
      end

      it "find page styles at root of templates dir" do
        @parent.layout = :standard_page
        @parent.render.must_equal "/Parent/\n"
      end

      it "find page styles in class sub dir" do
        @parent.layout = :subdir_style
        @parent.render.must_equal "<Parent>\n"
      end
    end

    describe "pages as inline content" do

      before do
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

      after do
        Object.send(:remove_const, :PageClass) rescue nil
      end

      it "use style assigned by entry" do
        @parent.contents.first.style.must_equal PageClass.default_style
        @parent.things.first.style.must_equal PageClass.default_style
      end

      it "use their default page style when accessed directly" do
        @page = PageClass[@page.id]
        @page.layout.must_equal PageClass.default_layout
        assert_correct_template(@parent, template_root / 'layouts/page_style', @renderer)
        @page.render.must_equal "<html></html>\n"
      end

      it "persist sub-page style settings" do
        @parent = Content[@parent.id]
        @parent.contents.first.style.must_equal PageClass.default_style
      end

      it "render using the inline style" do
        assert_correct_template(@parent.contents.first, template_root / 'page_class/inline_style', @renderer)
        @parent.contents.first.render.must_equal "Child\n"
        @parent.things.render.must_equal "Child\n"
        @parent.render.must_equal "<html>Child\n</html>\n"
      end

      it "renders using the inline style when loaded directly" do
        id = @page.id
        PageClass.layout(:html) { "=${::PageClass.get(#{id})}" }
        @parent.render.must_equal "=Child\n"
      end
    end

    describe "params in templates" do
      before do
        class ::TemplateParams < Page; end
        TemplateParams.field :image, :default => "/images/fromage.jpg"
        TemplateParams.layout :template_params
        @page = TemplateParams.new
      end
      after do
        Object.send(:remove_const, :TemplateParams) rescue nil
      end
      it "be passed to the render call" do
        @page.image.value.must_equal "/images/fromage.jpg"
        @page.image.src.must_equal "/images/fromage.jpg"
        @page.render.must_match /alt="Smelly"/
      end
    end
  end

  describe "Request rendering" do
    before do
      @site.paths.add(:templates, template_root)

      class ::PreviewRender < Page
        field :title, :string
      end
      class ::Image < Piece
        field :src
        template :html, "${ src }/ q={{ query }}"
      end

      PreviewRender.style :inline
      PreviewRender.box(:images) { allow :Image }
      PreviewRender.field :description, :markdown
      @page = PreviewRender.new(:title => "PAGE", :description => "DESCRIPTION")
      @page.save
      @session = ::Rack::MockSession.new(::Sinatra::Application)
    end

    after do
      Object.send(:remove_const, :PreviewRender)
      Object.send(:remove_const, :Image)
    end

    describe "Preview render" do
      before do
        @renderer = Spontaneous::Output::Template::PreviewRenderer.new(@site)
        PreviewRender.layout :preview_render
      end

      it "output both publish & request tags" do
        @now = Time.now
        ::Time.stubs(:now).returns(@now)
        @renderer.render_string('${title} {{ Time.now }}', @page.output(:html), {}).must_equal "PAGE #{@now.to_s}"
      end

      it "renders all includes before calling the request render stage" do
        PreviewRender.layout do
          "q={{ query }} <${ images }>"
        end
        @page.images << Image.new(src: 'fish.jpg')
        result = @page.render_using(@renderer, :html, { query: 'frog'})
        result.must_equal "q=frog <fish.jpg/ q=frog>"
      end

#       it "render all tags & include preview edit markers" do
#         @page.render.must_equal <<-HTML
# PAGE <p>DESCRIPTION</p>
#
# <!-- spontaneous:previewedit:start:box id:#{@page.images.schema_id} -->
# <!-- spontaneous:previewedit:end:box id:#{@page.images.schema_id} -->
#
#         HTML
#       end
    end
    describe "Request rendering" do
      before do
        @renderer = Spontaneous::Output::Template::PreviewRenderer.new(@site)
        PreviewRender.layout :params
      end

      it "pass on passed params" do
        result = @page.render_using(@renderer, :html, {
          :welcome => "hello"
        })
        result.must_equal "PAGE hello\n"
      end
    end


    describe "entry parameters" do
      before do
        @renderer = Spontaneous::Output::Template::PreviewRenderer.new(@site)
        PreviewRender.layout :entries
        @first = PreviewRender.new(:title => "first")
        @second = PreviewRender.new(:title => "second")
        @third = PreviewRender.new(:title => "third")
        @page.images << @first
        @page.images << @second
        @page.images << @third
        @page.save
        @page.reload
      end
      it "be available to templates" do
        @page.render.must_equal "0>first\n1second\n2<third\n0:first\n1:second\n2:third\nfirst.second.third\n"
      end
    end

    describe "Publishing renderer" do
      before do
        Spontaneous::Output.write_compiled_scripts = true
        @temp_template_root = @site.root / "templates"
        FileUtils.mkdir_p(@temp_template_root)
        FileUtils.mkdir_p(@temp_template_root / "layouts")
        @site.paths.add(:templates, @temp_template_root)

        @transaction = Spontaneous::Publishing::Transaction.new(@site, 99, nil)
        @renderer = Spontaneous::Output::Template::PublishRenderer.new(@transaction, true)

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

      # Disabled pending decision about the best way to optimize templates
      # in the case of this example, where we are optimizing the first render
      # of a site template (not a rendered page) I'm not sure that it's worth it
      # at all...
      it "ignore compiled template file if it is older than the template"
      #   @first.render_using(@renderer).must_equal "compiled"
      #   File.open(@temp_template_root / "layouts/standard.html.cut", "w") do |t|
      #     t.write("updated template")
      #   end
      #   later = Time.now + 1000
      #   File.utime(later, later, @template_path)
      #   template_mtime = File.mtime(@template_path)
      #   compiled_mtime = File.mtime(@compiled_path)
      #   assert template_mtime > compiled_mtime, "Template file should register as newer"
      #   # Need to use a new renderer because the existing one will have cached the compiled template
      #   @renderer = Spontaneous::Output::Template::PublishRenderer.new(@site)
      #   @first.render.must_equal "updated template"
      # end
    end

    describe "PublishedRenderer" do
      before do
        @site.background_mode = :immediate
        @site.output_store :Memory

        ::Spontaneous::State.delete
        ::Content.delete
        ::Content.delete_revision(1) rescue nil
        @renderer = Spontaneous::Output::Template::PublishedRenderer.new(@site, 1)
        Page.box :other
        class ::DynamicPage < Page
          layout(:html) { "${path}.${ __format }:{{ something }}"}
        end
        class ::StaticPage < Page
          layout(:html) { "${ path }.${ __format }"}
        end

        @root = Page.create
        assert @root.is_root?

        @dynamic = DynamicPage.new(slug: "dynamic", uid: "dynamic")
        @static = StaticPage.new(slug: "static", uid: "static")
        @root.other << @dynamic
        @root.other << @static

        [@root, @dynamic, @static].each(&:save)

        @site.publish do
          run :render_revision
          run :activate_revision
        end
        @site.publish_all
      end

      after do
        Object.send :remove_const, :StaticPage
        Object.send :remove_const, :DynamicPage
        ::Content.delete
      end

      it "should render dynamic pages from the template store xxx" do
        result = @renderer.render!(@dynamic.output(:html), { something: "something here" }, nil)
        result.must_equal "/dynamic.html:something here"
      end

      it "should render static pages from the template store xxx" do
        result = @renderer.render!(@static.output(:html), { something: "something here" }, nil)
        result.read.must_equal "/static.html"
      end
    end

    describe "variables in render command" do
      before do
        @transaction = Spontaneous::Publishing::Transaction.new(@site, 99, nil)
        @renderer = Spontaneous::Output::Template::PublishRenderer.new(@transaction)

        PreviewRender.layout :variables
        PreviewRender.style :variables

        @page.layout = :variables
        @first = PreviewRender.new(:title => "first")
        @page.images << @first
        @page.images.first.update(style: :variables)
        @page.save
      end

      it "be passed to page content" do
        @page.render(:html, :param => "param").must_equal "param\n<variable/param/>\n\nlocal\n"
      end
    end
  end
end

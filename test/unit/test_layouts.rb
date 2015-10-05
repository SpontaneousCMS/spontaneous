# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Layouts" do

  before do
    @template_root = ::File.expand_path('../../fixtures/layouts', __FILE__)
    @site = setup_site
    @site.paths.add(:templates, @template_root)
    class ::LayoutPage < ::Page; end
    class ::ABoxClass < ::Box; end
    class ::SubPage < LayoutPage; end
    ABoxClass.style :monkey
    ABoxClass.style :crazy

    class ::SomeContent < ::Piece; end
  end

  after do
    [:LayoutPage, :SubPage, :ABoxClass, :SomeContent].each do |c|
      Object.send(:remove_const, c) rescue nil
    end
    teardown_site
  end

  let(:renderer) { Spontaneous::Output.default_renderer(@site) }

  it "default to layouts/standard.html... if nothing defined" do
    page = LayoutPage.new
    assert_correct_template(page, @template_root / 'layouts/standard', renderer)
    page.render.must_equal "layouts/standard.html.cut\n"
  end

  it "use the named template if it exists" do
    layout = @template_root / "layouts/layout_page.html.cut"
    begin
      File.open(layout, "w") do |file|
        file.write("layouts/layout_page.html.cut\n")
      end
      page = LayoutPage.new
      assert_correct_template(page, @template_root / 'layouts/layout_page', renderer)
      page.render.must_equal "layouts/layout_page.html.cut\n"
    ensure
      FileUtils.rm(layout)
    end
  end

  it "return the first layout if some are declared but none declared default" do
    LayoutPage.layout :custom1
    LayoutPage.layout :custom2
    page = LayoutPage.new
    assert_correct_template(page, @template_root / 'layouts/custom1', renderer)
    page.render.must_equal "layouts/custom1.html.cut\n"
  end

  it "return the layout declared default" do
    LayoutPage.layout :custom1
    LayoutPage.layout :custom2, :default => true
    page = LayoutPage.new
    assert_correct_template(page, @template_root / 'layouts/custom2', renderer)
    page.render.must_equal "layouts/custom2.html.cut\n"
  end

  it "inherit templates from superclass" do
    LayoutPage.layout :custom1
    LayoutPage.layout :custom2, :default => true
    page = SubPage.new
    assert_correct_template(page, @template_root / 'layouts/custom2', renderer)
  end

  it "be able to overwrite inherited templates from superclass" do
    LayoutPage.layout :custom1
    LayoutPage.layout :custom2, :default => true
    SubPage.layout :custom3
    page = SubPage.new
    # page.layout.template.must_equal 'layouts/custom2'
    assert_correct_template(page, @template_root / 'layouts/custom2', renderer)
  end

  it "allow setting of style used" do
    LayoutPage.layout :custom1
    LayoutPage.layout :custom2
    page = LayoutPage.new
    assert_correct_template(page, @template_root / 'layouts/custom1', renderer)
    # page.layout.template.must_equal 'layouts/custom1'
    page.layout = :custom2
    assert_correct_template(page, @template_root / 'layouts/custom2', renderer)
    # page.layout.template.must_equal 'layouts/custom2'
  end

  it "use the last definied layout in sub-classes" do
    LayoutPage.layout :custom1
    LayoutPage.layout :custom2
    SubPage.layout :custom3
    SubPage.layout :custom4
    page = SubPage.new
    assert_correct_template(page, @template_root / 'layouts/custom3', renderer)
    page.layout = :custom2
    assert_correct_template(page, @template_root / 'layouts/custom2', renderer)
  end

  it "allow defining of default layout in sub-classes" do
    LayoutPage.layout :custom1
    LayoutPage.layout :custom2, :default => true
    SubPage.layout :custom3
    SubPage.layout :custom4, :default => true
    page = SubPage.new
    assert_correct_template(page, @template_root / 'layouts/custom4', renderer)
    page.layout = :custom3
    assert_correct_template(page, @template_root / 'layouts/custom3', renderer)
  end

  it "support blocks to set simple templates" do
    LayoutPage.field :title
    LayoutPage.layout do
      "${ title }!"
    end
    page = LayoutPage.new(:title => "john")
    page.render.must_equal "john!"
  end

  it "allows assigning a layout block to a particular output" do
    LayoutPage.add_output :rss
    LayoutPage.layout :html do
      "HTML"
    end
    LayoutPage.layout :rss do
      "RSS"
    end
    page = LayoutPage.new
    page.render(:html).must_equal "HTML"
    page.render(:rss).must_equal  "RSS"
  end

  it "allows a fallback layout block to render all formats" do
    LayoutPage.add_output :rss
    LayoutPage.layout do
      "${ __format }"
    end
    page = LayoutPage.new
    page.render(:html).must_equal "html"
    page.render(:rss).must_equal  "rss"
  end

  it "allows for using layouts in a subfolder" do
    LayoutPage.layout 'sub/custom1'
    page = SubPage.new
    assert_correct_template(page, @template_root / 'layouts/sub/custom1', renderer)
    LayoutPage.layout_prototypes[:'sub/custom1'].schema_name.split('/').last.must_equal "sub%2Fcustom1"
  end

  # it "raise error when setting unknown layout" do
  #   LayoutPage.layout :custom1
  #   LayoutPage.layout :custom2
  #   SubPage.layout :custom3
  #   page = SubPage.new
  #   lambda { page.layout = :wrong }.must_raise(Spontaneous::Errors::UnknownLayoutError)
  # end
  # it "have a list of formats" do
  #   LayoutPage.layout :custom1
  #   skip("Need to implement formats correctly")
  # end

  # it "be able to test that an instance supports a format" do
  #   skip("Need to implement formats correctly")
  #   LayoutPage.layout :custom1
  #   page = LayoutPage.new
  #   # page.provides_format?(:html).should be_true
  # end
end

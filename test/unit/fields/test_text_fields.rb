# encoding: UTF-8

require File.expand_path('../../../test_helper', __FILE__)

describe "Text fields" do
  before do
    @site = setup_site
    @now = Time.now
    stub_time(@now)
    Spontaneous::State.delete
    @site.background_mode = :immediate
  end

  after do
    teardown_site
  end
  describe "String fields" do
    before do
      @content_class = Class.new(::Piece) do
        field :title, :string
      end
      @instance = @content_class.new
      @field = @instance.title
    end

    it "should escape ampersands for the html format" do
      @field.value = "This & That"
      @field.value(:html).must_equal "This &amp; That"
    end

    it "be aliased to the :title type" do
      @content_class = Class.new(::Piece) do
        field :title, default: "Right"
        field :something, :title
      end
      instance = @content_class.new
      assert instance.fields.title.class.ancestors.include?(Spontaneous::Field::String), ":title type should inherit from StringField"
      instance.title.value.must_equal "Right"
    end
  end
  describe "Markdown fields" do
    before do
      class ::MarkdownContent < Piece
        field :text1, :markdown
        field :text2, :richtext
        field :text3, :markup
      end
      @instance = MarkdownContent.new
    end
    after do
      Object.send(:remove_const, :MarkdownContent)
    end

    it "be available as the :markdown type" do
      assert MarkdownContent.field_prototypes[:text1].field_class < Spontaneous::Field::Markdown
    end
    it "be available as the :richtext type" do
      assert MarkdownContent.field_prototypes[:text2].field_class < Spontaneous::Field::Markdown
    end
    it "be available as the :markup type" do
      assert MarkdownContent.field_prototypes[:text3].field_class < Spontaneous::Field::Markdown
    end

    it "process input into HTML" do
      @instance.text1 = "*Hello* **World**"
      @instance.text1.value.must_equal "<p><em>Hello</em> <strong>World</strong></p>\n"
    end

    it "use more sensible linebreaks" do
      @instance.text1 = "With\nLinebreak"
      @instance.text1.value.must_equal "<p>With<br />\nLinebreak</p>\n"
      @instance.text2 = "With  \nLinebreak"
      @instance.text2.value.must_equal "<p>With<br />\nLinebreak</p>\n"
    end
  end

  describe "LongString fields" do
    before do
      class ::LongStringContent < Piece
        field :long1, :longstring
        field :long2, :long_string
        field :long3, :text
      end
      @instance = LongStringContent.new
    end
    after do
      Object.send(:remove_const, :LongStringContent)
    end

    it "is available as the :longstring type" do
      assert LongStringContent.field_prototypes[:long1].field_class < Spontaneous::Field::LongString
    end

    it "is available as the :long_string type" do
      assert LongStringContent.field_prototypes[:long2].field_class < Spontaneous::Field::LongString
    end

    it "is available as the :text type" do
      assert LongStringContent.field_prototypes[:long3].field_class < Spontaneous::Field::LongString
    end

    it "translates newlines to <br/> tags" do
      @instance.long1 = "this\nlong\nstring"
      @instance.long1.value.must_equal "this<br />\nlong<br />\nstring"
    end
  end

  describe "HTML fields" do
    before do
      @content_class = Class.new(::Piece) do
        field :raw, :html
      end
      @content_class.stubs(:name).returns("ContentClass")
      @instance = @content_class.new
      @field = @instance.raw
    end

    it "does no escaping of input" do
      @field.value = "<script>\n</script>"
      @field.value(:html).must_equal "<script>\n</script>"
    end
  end

end

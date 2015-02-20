# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'fog'

describe "Fields" do

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

  describe "New content instances" do
    before do
      @content_class = Class.new(Piece) do
        field :title, :default => "Magic"
        field :thumbnail, :image
      end
      @instance = @content_class.new
    end

    it "have fields with values defined by prototypes" do
      f = @instance.fields[:title]
      assert f.class < Spontaneous::Field::String
      f.value.must_equal "Magic"
    end

    it "have shortcut access methods to fields" do
      @instance.fields.thumbnail.must_equal @instance.fields[:thumbnail]
    end
    it "have a shortcut setter on the Content fields" do
      @instance.fields.title = "New Title"
    end

    it "have a shortcut getter on the Content instance itself" do
      @instance.title.must_equal @instance.fields[:title]
    end

    it "have a shortcut setter on the Content instance itself" do
      @instance.title = "Boing!"
      @instance.fields[:title].value.must_equal "Boing!"
    end

    # TODO: I want to allow this but don't like overwriting the ::fields
    # method like this.
    # it "allow the definition of multiple fields at once" do
    #   content_class = Class.new(Piece) do
    #     fields :title, :photo, :date
    #   end
    # end
  end

  describe "Overwriting fields" do
    before do
      @class1 = Class.new(Piece) do
        field :title, :string, :default => "One"
        field :date, :string
      end
      @class2 = Class.new(@class1) do
        field :title, :image, :default => "Two", :title => "Two"
      end
      @class3 = Class.new(@class2) do
        field :date, :image, :default => "Three", :title => "Three"
      end
      @instance = @class2.new
    end

    it "overwrite field definitions" do
      @class2.fields.first.name.must_equal :title
      @class2.fields.last.name.must_equal :date
      @class2.fields.length.must_equal 2
      @class2.fields.title.schema_id.must_equal @class1.fields.title.schema_id
      @class2.fields.title.title.must_equal "Two"
      @class2.fields.title.title.must_equal "Two"
      @class3.fields.date.title.must_equal "Three"
      @class3.fields.date.schema_id.must_equal @class1.fields.date.schema_id
      assert @instance.title.class < Spontaneous::Field::Image
      @instance.title.value.to_s.must_equal "Two"
      instance1 = @class1.new
      instance3 = @class3.new
      @instance.title.schema_id.must_equal instance1.title.schema_id
      instance1.title.schema_id.must_equal instance3.title.schema_id
    end
  end
  describe "Field Prototypes" do
    before do
      @content_class = Class.new(Piece) do
        field :title
        field :synopsis, :string
      end
      @content_class.field :complex, :image, :default => "My default", :comment => "Use this to"
    end

    it "be creatable with just a field name" do
      @content_class.field_prototypes[:title].must_be_instance_of(Spontaneous::Prototypes::FieldPrototype)
      @content_class.field_prototypes[:title].name.must_equal :title
    end

    it "work with just a name & options" do
      @content_class.field :minimal, :default => "Small"
      @content_class.field_prototypes[:minimal].name.must_equal :minimal
      @content_class.field_prototypes[:minimal].default.must_equal "Small"
    end

    it "default to basic string class" do
      assert @content_class.field_prototypes[:title].instance_class < Spontaneous::Field::String
    end

    it "map :string type to Field::String" do
      assert @content_class.field_prototypes[:synopsis].instance_class < Spontaneous::Field::String
    end

    it "be listable" do
      @content_class.field_names.must_equal [:title, :synopsis, :complex]
    end

    it "be testable for existance" do
      assert @content_class.field?(:title)
      assert @content_class.field?(:synopsis)
      refute @content_class.field?(:non_existant)
      i = @content_class.new
      assert i.field?(:title)
      refute i.field?(:non_existant)
    end


    describe "default values" do
      before do
        @prototype = @content_class.field_prototypes[:title]
      end


      it "default to a value of ''" do
        @prototype.default.must_equal ""
      end

      it "get recieve calculated default values if default is a proc" do
        n = 0
        @content_class.field :dynamic, :default => proc { (n += 1) }
        instance = @content_class.new
        instance.dynamic.value.must_equal "1"
        instance = @content_class.new
        instance.dynamic.value.must_equal "2"
      end

      it "be able to calculate default values based on properties of owner" do
        @content_class.field :dynamic, :default => proc { |owner| owner.title.value }
        instance = @content_class.new(:title => "Frog")
        instance.dynamic.value.must_equal "Frog"
      end

      it "match name to type if sensible" do
        content_class = Class.new(Piece) do
          field :image
          field :date
          field :chunky
        end

        assert content_class.field_prototypes[:image].field_class < Spontaneous::Field::Image
        assert content_class.field_prototypes[:date].field_class < Spontaneous::Field::Date
        assert content_class.field_prototypes[:chunky].field_class < Spontaneous::Field::String
      end

      it "assigns the value of the field if the default is a proc" do
        n = 0
        f = @content_class.field :dynamic, :default => proc { (n += 1) }
        f.dynamic_default?.must_equal true
        instance1 = @content_class.create
        instance1.dynamic.value.must_equal "1"
        instance1.reload
        instance1.dynamic.value.must_equal "1"
      end

      it "uses a dynamic default value to set the page slug" do
        n = 0
        page_class = Class.new(::Page)
        page_class.field :title, default: proc { (n += 1) }
        page = page_class.create
        page.slug.must_equal "1"
      end
    end

    describe "Field titles" do
      before do
        @content_class = Class.new(Piece) do
          field :title
          field :having_fun_yet
          field :synopsis, :title => "Custom Title"
          field :description, :title => "Simple Description"
        end
        @title = @content_class.field_prototypes[:title]
        @having_fun = @content_class.field_prototypes[:having_fun_yet]
        @synopsis = @content_class.field_prototypes[:synopsis]
        @description = @content_class.field_prototypes[:description]
      end

      it "default to a sensible title" do
        @title.title.must_equal "Title"
        @having_fun.title.must_equal "Having Fun Yet"
        @synopsis.title.must_equal "Custom Title"
        @description.title.must_equal "Simple Description"
      end
    end
    describe "option parsing" do
      before do
        @prototype = @content_class.field_prototypes[:complex]
      end

      it "parse field class" do
        assert @prototype.field_class < Spontaneous::Field::Image
      end

      it "parse default value" do
        @prototype.default.must_equal "My default"
      end

      it "parse ui comment" do
        @prototype.comment.must_equal "Use this to"
      end
    end

    describe "sub-classes" do
      before do
        @subclass = Class.new(@content_class) do
          field :child_field
        end
        @subsubclass = Class.new(@subclass) do
          field :distant_relation
        end
      end

      it "inherit super class's field prototypes" do
        @subclass.field_names.must_equal [:title, :synopsis, :complex, :child_field]
        @subsubclass.field_names.must_equal [:title, :synopsis, :complex, :child_field, :distant_relation]
      end

      it "deal intelligently with manual setting of field order" do
        @reordered_class = Class.new(@subsubclass) do
          field_order :child_field, :complex
        end
        @reordered_class.field_names.must_equal [:child_field, :complex, :title, :synopsis, :distant_relation]
      end
    end

    describe "fallback values" do
      before do
        @content_class = Class.new(Piece) do
          field :title
          field :desc1, :fallback => :title
          field :desc2, :fallback => :desc1
          field :desc3, :fallback => :desc9
        end
        Object.send :const_set, :FieldWithFallbacks, @content_class
        @instance = @content_class.new(:title => "TITLE")
      end

      after do
        Object.send :remove_const, :FieldWithFallbacks rescue nil
      end

      it "uses the fallback value for empty fields" do
        @instance.desc1.value.must_equal "TITLE"
      end

      it "cascades the fallback" do
        @instance.desc2.value.must_equal "TITLE"
      end

      it "uses the field value if present" do
        @instance.desc2 = "DESC2"
        @instance.desc2.value.must_equal "DESC2"
      end

      it "deserializes values properly" do
        @instance.desc2 = "DESC2"
        @instance.save
        @instance.reload
        @instance.desc2.processed_values[:html].must_equal "DESC2"
      end

      it "ignores invalid field names" do
        @instance.desc3.value.must_equal ""
      end
    end
  end

  describe "Values" do
    before do
      @field_class = Class.new(S::Field::Base) do
        def outputs
          [:html, :plain, :fancy]
        end
        def generate_html(value, site)
          "<#{value}>"
        end
        def generate_plain(value, site)
          "*#{value}*"
        end

        def generate(output, value, site)
          case output
          when :fancy
            "#{value}!"
          else
            value
          end
        end
      end
      @field = @field_class.new
    end

    it "be used as the comparator" do
      f1 = @field_class.new
      f1.value = "a"
      f2 = @field_class.new
      f2.value = "b"
      (f1 <=> f2).must_equal -1
      (f2 <=> f1).must_equal 1
      (f1 <=> f1).must_equal 0
      [f2, f1].sort.map(&:value).must_equal ["<a>", "<b>"]
    end

    it "be transformed by the update method" do
      @field.value = "Hello"
      @field.value.must_equal "<Hello>"
      @field.value(:html).must_equal "<Hello>"
      @field.value(:plain).must_equal "*Hello*"
      @field.value(:fancy).must_equal "Hello!"
      @field.unprocessed_value.must_equal "Hello"
    end

    it "appear in the to_s method" do
      @field.value = "String"
      @field.to_s.must_equal "<String>"
      @field.to_s(:html).must_equal "<String>"
      @field.to_s(:plain).must_equal "*String*"
    end

    it "escape ampersands by default" do
      field_class = Class.new(S::Field::String) do
      end
      field = field_class.new
      field.value = "Hello & Welcome"
      field.value(:html).must_equal "Hello &amp; Welcome"
      field.value(:plain).must_equal "Hello & Welcome"
    end

    it "educate quotes" do
      field_class = Class.new(S::Field::String)
      field = field_class.new
      field.value = %("John's first... example")
      field.value(:html).must_equal "“John’s first… example”"
      field.value(:plain).must_equal "“John’s first… example”"
    end

    it "not process values coming from db" do
      class ContentClass1 < Piece
      end
      $transform = lambda { |value| "<#{value}>" }
      ContentClass1.field :title do
        def generate_html(value, site)
          $transform[value]
        end
      end
      instance = ContentClass1.new
      instance.fields.title = "Monkey"
      instance.save

      $transform = lambda { |value| "*#{value}*" }
      instance = ContentClass1[instance.id]
      instance.fields.title.value.must_equal "<Monkey>"
      Object.send(:remove_const, :ContentClass1)
    end
  end

  describe "field instances" do
    before do
      ::CC = Class.new(Piece) do
        field :title, :default => "Magic" do
          def generate_html(value, site)
            "*#{value}*"
          end
        end
      end
      @instance = CC.new
    end

    after do
      Object.send(:remove_const, :CC)
    end

    it "have a link back to their owner" do
      @instance.fields.title.owner.must_equal @instance
    end

    it "be created with the right default value" do
      f = @instance.fields.title
      f.value.must_equal "*Magic*"
    end

    it "eval blocks from prototype defn" do
      f = @instance.fields.title
      f.value = "Boo"
      f.value.must_equal "*Boo*"
      f.unprocessed_value.must_equal "Boo"
    end

    it "have a reference to their prototype" do
      f = @instance.fields.title
      f.prototype.must_equal CC.field_prototypes[:title]
    end

    it "return the item which isnt empty when using the / method" do
      a = CC.new(:title => "")
      b = CC.new(:title => "b")
      (a.title / b.title).must_equal b.title
      a.title = "a"
      (a.title / b.title).must_equal a.title
    end

    it "return the item which isnt empty when using the | method" do
      a = CC.new(:title => "")
      b = CC.new(:title => "b")
      (a.title | b.title).must_equal b.title
      a.title = "a"
      (a.title | b.title).must_equal a.title
    end

    it "return the item which isnt empty when using the or method" do
      a = CC.new(:title => "")
      b = CC.new(:title => "b")
      (a.title.or(b.title)).must_equal b.title
      a.title = "a"
      (a.title.or(b.title)).must_equal a.title
    end

  end

  describe "Field value persistence" do
    before do
      class ::PersistedField < Piece
        field :title, :default => "Magic"
      end
    end
    after do
      Object.send(:remove_const, :PersistedField)
    end

    it "work" do
      instance = ::PersistedField.new
      instance.fields.title.value = "Changed"
      instance.save
      id = instance.id
      instance = ::PersistedField[id]
      instance.fields.title.value.must_equal "Changed"
    end
  end

  describe "Value version" do
    before do
      class ::PersistedField < Piece
        field :title, :default => "Magic"
      end
    end
    after do
      Object.send(:remove_const, :PersistedField)
    end

    it "be increased after a change" do
      instance = ::PersistedField.new
      instance.fields.title.version.must_equal 0
      instance.fields.title.value = "Changed"
      instance.save
      instance = ::PersistedField[instance.id]
      instance.fields.title.value.must_equal "Changed"
      instance.fields.title.version.must_equal 1
    end

    it "not be increased if the value remains constant" do
      instance = ::PersistedField.new
      instance.fields.title.version.must_equal 0
      instance.fields.title.value = "Changed"
      instance.save
      instance = ::PersistedField[instance.id]
      instance.fields.title.value = "Changed"
      instance.save
      instance = ::PersistedField[instance.id]
      instance.fields.title.value.must_equal "Changed"
      instance.fields.title.version.must_equal 1
      instance.fields.title.value = "Changed!"
      instance.save
      instance = ::PersistedField[instance.id]
      instance.fields.title.version.must_equal 2
    end
  end

  describe "Available output formats" do
    it "include HTML & PDF and default to default value" do
      f = S::Field::Base.new
      f.value = "Value"
      f.to_html.must_equal "Value"
      f.to_pdf.must_equal "Value"
    end
  end


  describe "Editor classes" do
    it "be defined in base types" do
      base_class = Spontaneous::Field::Image
      base_class.editor_class.must_equal "Spontaneous.Field.Image"
      base_class = Spontaneous::Field::Date
      base_class.editor_class.must_equal "Spontaneous.Field.Date"
      base_class = Spontaneous::Field::Markdown
      base_class.editor_class.must_equal "Spontaneous.Field.Markdown"
      base_class = Spontaneous::Field::String
      base_class.editor_class.must_equal "Spontaneous.Field.String"
    end

    it "be inherited in subclasses" do
      base_class = Spontaneous::Field::Image
      @field_class = Class.new(base_class)
      @field_class.stubs(:name).returns("CustomField")
      @field_class.editor_class.must_equal base_class.editor_class
      @field_class2 = Class.new(@field_class)
      @field_class2.stubs(:name).returns("CustomField2")
      @field_class2.editor_class.must_equal base_class.editor_class
    end
    it "correctly defined by field prototypes" do
      base_class = Spontaneous::Field::Image
      class ::CustomField < Spontaneous::Field::Image
        self.register(:custom)
      end

      class ::CustomContent < ::Piece
        field :custom
      end
      assert CustomContent.fields.custom.instance_class < CustomField

      CustomContent.fields.custom.instance_class.editor_class.must_equal Spontaneous::Field::Image.editor_class

      Object.send(:remove_const, :CustomContent)
      Object.send(:remove_const, :CustomField)
    end
  end

  describe "Field versions" do
    before do
      @user = Spontaneous::Permissions::User.create(:email => "user@example.com", :login => "user", :name => "user", :password => "rootpass")
      @user.reload

      class ::Piece
        field :title
      end
      # @content_class.stubs(:name).returns("ContentClass")
      @instance = ::Piece.create
    end

    after do
      # Object.send(:remove_const, :Piece) rescue nil
      Spontaneous::Permissions::User.delete
      ::Content.delete
      S::Field::FieldVersion.delete
    end

    it "start out as empty" do
      assert @instance.title.versions.empty?, "Field version list should be empty"
    end

    it "be created every time a field is modified" do
      @instance.title.value = "one"
      @instance.save.reload
      v = @instance.title.versions
      v.count.must_equal 1
    end

    it "marks a field as unmodified after save" do
      @instance.title.value = "one"
      @instance.save.reload
      @instance.title.modified?.must_equal false
    end

    it "have a creation date" do
      now = Time.now + 1000
      stub_time(now)
      @instance.title.value = "one"
      @instance.save.reload
      @instance.reload
      vv = @instance.title.versions
      v = vv.first
      v.created_at.to_i.must_equal now.to_i
    end

    it "save the previous value" do
      stub_time(@now)
      @instance.title.value = "one"
      @instance.save.reload
      vv = @instance.title.versions
      v = vv.first
      v.value.must_equal ""
      stub_time(@now+10)
      @instance.title.value = "two"
      @instance.save.reload
      vv = @instance.title.versions
      v = vv.first
      v.value.must_equal "one"
      stub_time(@now+20)
      @instance.title.value = "three"
      @instance.save.reload
      vv = @instance.title.versions
      v = vv.first
      v.value.must_equal "two"
    end

    it "keep a track of the version number" do
      stub_time(@now)
      @instance.title.value = "one"
      @instance.save.reload
      vv = @instance.title.versions
      v = vv.first
      v.version.must_equal 1
      stub_time(@now+10)
      @instance.title.value = "two"
      @instance.save.reload
      vv = @instance.title.versions
      vv.count.must_equal 2
      v = vv.first
      v.version.must_equal 2
    end

    it "remember the responsible editor" do
      @instance.current_editor = @user
      @instance.title.value = "one"
      @instance.save.reload
      vv = @instance.title.versions
      v = vv.first
      v.user.must_equal @user
    end

    it "have quick access to the last version" do
      stub_time(@now)
      @instance.title.value = "one"
      @instance.save.reload
      vv = @instance.title.versions
      v = vv.first
      v.value.must_equal ""
      stub_time(@now+10)
      @instance.title.value = "two"
      @instance.save.reload
      vv = @instance.title.versions
      v = vv.first
      v.value.must_equal "one"
      @instance.title.previous_version.value.must_equal "one"
    end
  end

  describe "Asynchronous processing" do
    before do
      @site.background_mode = :simultaneous
      @image = File.expand_path("../../fixtures/images/size.gif", __FILE__)
      @model = (::Piece)
      @model.field :title
      @model.field :image
      @model.field :description, :markdown
      @model.box :items do
        field :title
        field :image
      end
      @instance = @model.create
    end

    # it "be disabled if the background mode is set to immediate" do
    #   S::Site.background_mode = :immediate
    #   S::Field::Update.asynchronous_update_class.must_equal S::Field::Update::Immediate
    # end

    # it "be enabled if the background mode is set to simultaneous" do
    #   S::Site.background_mode = :simultaneous
    #   S::Field::Update.asynchronous_update_class.must_equal S::Field::Update::Simultaneous
    # end

    it "be able to resolve fields id" do
      S::Field.find(@site.model, @instance.image.id, @instance.items.title.id).must_equal [
        @instance.image, @instance.items.title
      ]
    end

    it "not raise errors for invalid fields" do
      S::Field.find(@site.model, "0", "#{@instance.id}/xxx/#{@instance.items.title.schema_id}", "#{@instance.items.id}/nnn", @instance.items.title.id).must_equal [ @instance.items.title ]
    end

    it "return a single field if given a single id" do
      S::Field.find(@site.model, @instance.image.id).must_equal @instance.image
    end

    it "be disabled for Date fields" do
      f = S::Field::Date.new
      refute f.asynchronous?
    end

    it "be disabled for Location fields" do
      f = S::Field::Location.new
      refute f.asynchronous?
    end

    it "be disabled for LongString fields" do
      f = S::Field::LongString.new
      refute f.asynchronous?
    end

    it "be disabled for Markdown fields" do
      f = S::Field::Markdown.new
      refute f.asynchronous?
    end

    it "be disabled for Select fields" do
      f = S::Field::Select.new
      refute f.asynchronous?
    end

    it "be disabled for String fields" do
      f = S::Field::String.new
      refute f.asynchronous?
    end

    it "be disabled for WebVideo fields" do
      f = S::Field::WebVideo.new
      refute f.asynchronous?
    end

    it "be enabled for File fields" do
      f = S::Field::File.new
      assert f.asynchronous?
    end

    it "be enabled for Image fields" do
      f = S::Field::Image.new
      assert f.asynchronous?
    end

    it "immediately update a group of fields passed in parameter format" do
      field = @instance.image
      File.open(@image, "r") do |file|
        fields = {
          @instance.title.schema_id.to_s => "Updated title",
          @instance.image.schema_id.to_s => {:tempfile => file, :filename => "something.gif", :type => "image/gif"},
          @instance.description.schema_id.to_s => "Updated description"
        }
        Spontaneous::Field.update(@site, @instance, fields, nil, false)
        @instance.reload
        @instance.title.value.must_equal "Updated title"
        @instance.description.value.must_equal "<p>Updated description</p>\n"
        field.value.must_equal "/media/#{S::Media.pad_id(@instance.id)}/0001/something.gif"
      end
    end

    it "asynchronously update a group of fields passed in parameter format" do
      field = @instance.image
      Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
        "fields" => [field.id]
      })

      File.open(@image, "r") do |file|
        fields = {
          @instance.title.schema_id.to_s => "Updated title",
          @instance.image.schema_id.to_s => {:tempfile => file, :filename => "something.gif", :type => "image/gif"},
          @instance.description.schema_id.to_s => "Updated description"
        }
        @instance.expects(:save).at_least_once

        Spontaneous::Field.update(@site, @instance, fields, nil, true)

        @instance.title.value.must_equal "Updated title"
        @instance.description.value.must_equal "<p>Updated description</p>\n"
        field.value.must_equal ""
        field.pending_value.must_equal({
          :timestamp => S::Field.timestamp(@now),
          :version => 1,
          :value => {
            :width=>50, :height=>67, :dimensions => [50,67], :filesize=>3951,
            :storage_name=>"default",
            :type=>"image/gif", :format => "gif",
            :tempfile=>"#{@site.root}/cache/media/tmp/#{field.media_id}/something.gif",
          :filename=>"something.gif",
          :src => "/media/tmp/#{field.media_id}/something.gif"
          }
        })
        field.process_pending_value
        field.value.must_equal "/media/#{S::Media.pad_id(@instance.id)}/0001/something.gif"
        field.pending_value.must_be_nil
      end
    end

    it "asynchronously update a single field value" do
      field = @instance.image
      Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
        "fields" => [field.id]
      })
      File.open(@image, "r") do |file|
        field.pending_version.must_equal 0
        Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
        field.value.must_equal ""
        field.pending_value.must_equal({
          :timestamp => S::Field.timestamp(@now),
          :version => 1,
          :value => {
            :width=>50, :height=>67, :dimensions => [50,67], :filesize=>3951,
            :storage_name=>"default",
            :type=>"image/gif", :format => "gif",
            :tempfile=>"#{@site.root}/cache/media/tmp/#{field.media_id}/something.gif",
          :filename=>"something.gif",
          :src => "/media/tmp/#{field.media_id}/something.gif"
          }
        })
        field.pending_version.must_equal 1
        field.process_pending_value
        field.value.must_equal "/media/#{S::Media.pad_id(@instance.id)}/0001/something.gif"
      end
    end

    it "synchronously update box fields" do
      box = @instance.items
      File.open(@image, "r") do |file|
        fields = {
          box.title.schema_id.to_s => "Updated title",
          box.image.schema_id.to_s => {:tempfile => file, :filename => "something.gif", :type => "image/gif"}
        }
        Spontaneous::Field.update(@site, box, fields, nil, false)
        box.title.value.must_equal "Updated title"
        box.image.value.must_equal "/media/#{S::Media.pad_id(@instance.id)}/#{box.schema_id}/0001/something.gif"
        box.image.pending_version.must_equal 1
      end
    end

    it "asynchronously update box fields" do
      box = @instance.items
      field = box.image
      Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
        "fields" => [field.id]
      })
      File.open(@image, "r") do |file|
        fields = {
          box.title.schema_id.to_s => "Updated title",
          box.image.schema_id.to_s => {:tempfile => file, :filename => "something.gif", :type => "image/gif"}
        }
        Spontaneous::Field.update(@site, box, fields, nil, true)
        box.title.value.must_equal "Updated title"
        field.value.must_equal ""
        field.pending_value.must_equal({
          :timestamp => S::Field.timestamp(@now),
          :version => 1,
          :value => {
            :width=>50, :height=>67, :dimensions => [50,67], :filesize=>3951,
            :storage_name=>"default",
            :type=>"image/gif", :format => "gif",
            :tempfile=>"#{@site.root}/cache/media/tmp/#{field.media_id}/something.gif",
          :filename=>"something.gif",
          :src => "/media/tmp/#{field.media_id}/something.gif"
          }
        })
      end
    end

    it "deletes used temp files after processing" do
      field = @instance.image
      tempfile = "#{@site.root}/cache/media/tmp/#{field.media_id}/something.gif"
      Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
        "fields" => [field.id]
      })
      File.open(@image, "r") do |file|
        field.pending_version.must_equal 0
        Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
        field.value.must_equal ""
        field.pending_value.must_equal({
          :timestamp => S::Field.timestamp(@now),
          :version => 1,
          :value => {
            :width=>50, :height=>67, :dimensions => [50,67], :filesize=>3951,
            :storage_name=>"default",
            :type=>"image/gif", :format => "gif",
            :tempfile=>"#{@site.root}/cache/media/tmp/#{field.media_id}/something.gif",
          :filename=>"something.gif",
          :src => "/media/tmp/#{field.media_id}/something.gif"
          }
        })
        field.pending_version.must_equal 1
        assert ::File.exist?(tempfile)
        field.process_pending_value
        field.value.must_equal "/media/#{S::Media.pad_id(@instance.id)}/0001/something.gif"
      end
      refute ::File.exist?(tempfile)
    end

    it "immediately update asynchronous fields if background mode is :immediate" do
      @site.background_mode = :immediate
      field = @instance.image
      File.open(@image, "r") do |file|
        fields = {
          field.schema_id.to_s => {:tempfile => file, :filename => "something.gif", :type => "image/gif"}
        }
        Spontaneous::Simultaneous.expects(:fire).never
        Spontaneous::Field.update(@site, @instance, fields, nil, true)
        @instance.image.value.must_equal "/media/#{S::Media.pad_id(@instance.id)}/0001/something.gif"
      end
    end

    it "immediately updates file fields when their new value is empty" do
      Spontaneous::Simultaneous.stubs(:fire)
      field = @instance.image
      File.open(@image, "r") do |file|
        fields = {
          field.schema_id.to_s => {:tempfile => file, :filename => "something.gif", :type => "image/gif"}
        }
        Spontaneous::Field.update(@site, @instance, fields, nil, false)
        @instance.reload
        field = @instance.image
        field.value.must_equal "/media/#{S::Media.pad_id(@instance.id)}/0001/something.gif"
        field.pending_value.must_be_nil
      end
      fields = {field.schema_id.to_s => ""}
      Spontaneous::Field.update(@site, @instance, fields, nil, true)
      @instance.reload
      field = @instance.image
      field.value.must_equal ""
      field.pending_value.must_be_nil
    end

    it "not update a field if user does not have necessary permissions" do
      user = mock()
      @instance.title.expects(:writable?).with(user).at_least_once.returns(false)
      fields = {
        @instance.title.schema_id.to_s => "Updated title"
      }
      Spontaneous::Field.update(@site, @instance, fields, user, true)
      @instance.title.value.must_equal ""
    end

    it "call Fields::Update::Immediate from the cli" do
      immediate = mock()
      immediate.expects(:pages).returns([])
      immediate.expects(:run)
      Spontaneous::Field::Update::Immediate.expects(:new).with(@site, [@instance.image, @instance.items.title]).returns(immediate)
      # Thor generates a warning about creating a task with no 'desc'
      silence_logger {
        Spontaneous::Cli::Fields.any_instance.stubs(:prepare!)
      }
      Spontaneous::Cli::Fields.start(["update", "--fields", @instance.image.id, @instance.items.title.id])
    end

    it "call Fields::Update::Immediate from the cli with a single field" do
      silence_logger {
        Spontaneous::Cli::Fields.any_instance.stubs(:prepare!)
      }
      Spontaneous::Cli::Fields.start(["update", "--fields", @instance.image.id])
    end

    it "revert to immediate updating if connection to simultaneous fails" do
      File.open(@image, "r") do |file|
        Spontaneous::Field.set(@site, @instance.image, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
        @instance.image.value.must_equal "/media/#{S::Media.pad_id(@instance.id)}/0001/something.gif"
        @instance.image.pending_value.must_be_nil
      end
    end

    it "includes a local temp url for fields with pending values" do
      field = @instance.image
      Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
        "fields" => [field.id]
      })
      File.open(@image, "r") do |file|
        field.pending_version.must_equal 0
        Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
        export = field.export
        values = export[:processed_value]
        assert values.key?(:__pending__)
        pending = values[:__pending__][:value]
        pending[:src].must_match %r{^/media/}
      end
    end

    describe "page locks" do
      before do
        @now = Time.now
        stub_time(@now)
        LockedPage = Class.new(::Page)
        LockedPage.field :image
        LockedPage.box :instances do
          field :image
          field :title
        end
        LockedPiece = @model
        @page = LockedPage.create
        @instance = LockedPiece.create
        @page.instances << @instance
        @page.save.reload
        @instance.save.reload
        # The PageLock associations cache the Content model
        # but since this changes every time later tests
        # use an old version of Content with an old schema
        S::PageLock.all_association_reflections.each do |r|
          # Clear the cached class
          r[:cache] = {}
        end
      end

      after do
        Spontaneous::PageLock.delete
        Object.send :remove_const, :LockedPage rescue nil
        Object.send :remove_const, :LockedPiece rescue nil
      end

      it "be created when scheduling a page field for async updating" do
        Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
          "fields" => [@page.image.id]
        })
        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, @page.image, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
          @page.image.value.must_equal ""
          @page.update_locks.length.must_equal 1
          lock = @page.update_locks.first
          lock.field.must_equal @page.image
          lock.content.must_equal @page
          lock.page.must_equal @page
          lock.description.must_match /something\.gif/
          lock.created_at.must_equal @now
          lock.location.must_equal "Field ‘image’"
          assert @page.locked_for_update?
        end
      end

      it "not create locks for fields processed immediately" do
        field = @instance.title
        Spontaneous::Field.set(@site, field, "Updated Title", nil, true)
        field.value.must_equal "Updated Title"
        @page.update_locks.length.must_equal 0
        refute @page.locked_for_update?
      end

      it "be created when scheduling a box field for async updating" do
        field = @page.instances.image
        Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
          "fields" => [field.id]
        })
        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
          field.value.must_equal ""
          @page.update_locks.length.must_equal 1
          lock = @page.update_locks.first
          lock.field.must_equal field.reload
          lock.content.must_equal @page.reload
          lock.page.must_equal @page
          lock.description.must_match /something\.gif/
          lock.created_at.must_equal @now
          lock.location.must_equal "Field ‘image’ of box ‘instances’"
          assert @page.locked_for_update?
        end
      end

      it "be created when scheduling a piece field for async updating" do
        field = @instance.image
        Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
          "fields" => [field.id]
        })
        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
          field.value.must_equal ""
          @page.update_locks.length.must_equal 1
          lock = @page.update_locks.first
          lock.field.must_equal field
          lock.content.must_equal @instance
          lock.page.reload.must_equal @page.reload
          lock.description.must_match /something\.gif/
          lock.created_at.must_equal @now
          lock.location.must_equal "Field ‘image’ of entry 1 in box ‘instances’"
          assert @page.locked_for_update?
        end
      end

      it "be removed when the field has been processed" do
        Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
          "fields" => [@page.image.id]
        })
        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, @page.image, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
          @page.image.value.must_equal ""
          @page.update_locks.length.must_equal 1
          assert @page.locked_for_update?
          # The lock manipulation is done by the updater
          # so calling update_pending_value on the field
          # won't clear any locks
          Spontaneous::Field::Update::Immediate.process(@site, [@page.image])
          @page.image.value.must_equal "/media/#{@page.id.to_s.rjust(5, "0")}/0001/something.gif"
          refute @page.reload.locked_for_update?
        end
      end

      it "send a completion event that includes a list of unlocked pages" do
        field = @instance.image
        Spontaneous::Simultaneous.expects(:fire).with(:update_fields, {
          "fields" => [field.id]
        })
        Simultaneous.expects(:send_event).with('page_lock_status', "[#{@page.id}]")

        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
          assert @page.locked_for_update?
          silence_logger {
            Spontaneous::Cli::Fields.any_instance.stubs(:prepare!)
          }
          Spontaneous::Cli::Fields.start(["update", "--fields", field.id])
        end
      end

      it "ignore an update that has been superceded" do
        # user uploads an image and then changes their mind and uploads another
        # before the first one has been processed.
        # Pending value might have changed between the start of the update and the end
        # especially in the case of video processing or file upload
        # Before we update the value of a field or
        # clear pending values we need to be sure that they aren't still needed
        #

        field = @instance.image
        Spontaneous::Simultaneous.expects(:fire).at_least_once.with(:update_fields, {
          "fields" => [field.id]
        })
        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
        end
        update = Spontaneous::Field::Update::Immediate.new(@site, field)
        old, field = field, field.reload
        later = @now + 1
        t = S::Field.timestamp(later)
        S::Field.stubs(:timestamp).returns(t)
        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "else.gif", :type => "image/jpeg"}, nil, true)
        end
        update.run

        pending = field.pending_value
        pending[:value][:filename].must_equal "else.gif"
      end

      it "merge async updates with synchronous ones affected during processing" do
        # Scenario:
        # - User uploads file to content item which gets scheduled for async processing
        # - User modifies synchronous field of same content item that gets immediately updated
        # - Async process completes and...
        #   SHOULD
        #   Keep the updated values from the immediate change
        #   Merge in the results of the async change
        field = @instance.image
        Spontaneous::Simultaneous.expects(:fire).at_least_once.with(:update_fields, {
          "fields" => [field.id]
        })
        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
        end
        # Create update but don't run it
        update = Spontaneous::Field::Update::Immediate.new(@site, field)
        # Someone updates a field before the async update is run...
        content = ::Content.get(@instance.id)
        content.title = "Updated Title"
        content.save

        # Now run the update with a field that's out of sync with the version in the db
        update.run

        content = ::Content.get(@instance.id)
        content.title.value.must_equal "Updated Title"
        content.image.value.must_equal "/media/#{S::Media.pad_id(@instance.id)}/0001/something.gif"
      end

      it "merge async updates to box fields with synchronous ones affected during processing" do
        # The scenario for boxes is more complex because their fields are stored by their owner
        # not directly by themselves
        field = @page.instances.image
        Spontaneous::Simultaneous.expects(:fire).at_least_once.with(:update_fields, {
          "fields" => [field.id]
        })
        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
        end
        # Create update but don't run it
        update = Spontaneous::Field::Update::Immediate.new(@site, field)
        # Someone updates a field before the async update is run...
        content = ::Content.get(@page.id)
        content.instances.title = "Updated Title"
        content.save

        # Now run the update with a field that's out of sync with the version in the db
        update.run


        content = ::Content.get(@page.id)
        content.instances.title.value.must_equal "Updated Title"
        content.instances.image.value.must_equal "/media/#{S::Media.pad_id(@page.id)}/#{@page.instances.schema_id}/0001/something.gif"
      end

      it "removes temporary files after processing" do
      end

      it "be deleted when their page is deleted" do
        @page.image.stubs(:page_lock_description).returns("Lock description")
        lock = Spontaneous::PageLock.lock_field(@page.image)
        @page.destroy
        found = Spontaneous::PageLock[lock.id]
        found.must_be_nil
      end

      it "be deleted when their owning content is deleted" do
        LockedPiece.field :title
        @instance.title.stubs(:page_lock_description).returns("Lock description")
        lock = Spontaneous::PageLock.lock_field(@instance.title)
        @instance.destroy
        found = Spontaneous::PageLock.filter(:content_id => @instance.id).first
        found.must_be_nil
      end

      it "deals gracefully with updating content that has been deleted" do
        field = @page.image
        Spontaneous::Simultaneous.expects(:fire).at_least_once.with(:update_fields, {
          "fields" => [field.id]
        })
        File.open(@image, "r") do |file|
          Spontaneous::Field.set(@site, field, {:tempfile => file, :filename => "something.gif", :type => "image/gif"}, nil, true)
        end
        # Create update but don't run it
        update = Spontaneous::Field::Update::Immediate.new(@site, field)

        @page.destroy

        update.run

        Content[@page.id].must_be_nil
      end
    end
  end
end

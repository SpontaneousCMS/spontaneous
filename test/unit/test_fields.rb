# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class FieldsTest < MiniTest::Spec

  def setup
    @site = setup_site
    Site.publishing_method = :immediate
  end

  def teardown
    teardown_site
  end

  context "Fields" do
    setup do
      class ::Page < Spontaneous::Page; end
      class ::Piece < Spontaneous::Piece; end
    end

    teardown do
      Object.send(:remove_const, :Page)
      Object.send(:remove_const, :Piece)
    end

    context "New content instances" do
      setup do
        @content_class = Class.new(Piece) do
          field :title, :default => "Magic"
          field :thumbnail, :image
        end
        @instance = @content_class.new
      end

      should "have fields with values defined by prototypes" do
        f = @instance.fields[:title]
        assert f.class < Spontaneous::FieldTypes::StringField
        f.value.should == "Magic"
      end

      should "have shortcut access methods to fields" do
        @instance.fields.thumbnail.should == @instance.fields[:thumbnail]
      end
      should "have a shortcut setter on the Content fields" do
        @instance.fields.title = "New Title"
      end

      should "have a shortcut getter on the Content instance itself" do
        @instance.title.should == @instance.fields[:title]
      end

      should "have a shortcut setter on the Content instance itself" do
        @instance.title = "Boing!"
        @instance.fields[:title].value.should == "Boing!"
      end
    end

    context "Overwriting fields" do
      setup do
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

      should "overwrite field definitions" do
        @class2.fields.first.name.should == :title
        @class2.fields.last.name.should == :date
        @class2.fields.length.should == 2
        @class2.fields.title.schema_id.should == @class1.fields.title.schema_id
        @class2.fields.title.title.should == "Two"
        @class2.fields.title.title.should == "Two"
        @class3.fields.date.title.should == "Three"
        @class3.fields.date.schema_id.should == @class1.fields.date.schema_id
        assert @instance.title.class < Spontaneous::FieldTypes::ImageField
        @instance.title.value.to_s.should == "Two"
        instance1 = @class1.new
        instance3 = @class3.new
        @instance.title.schema_id.should == instance1.title.schema_id
        instance1.title.schema_id.should == instance3.title.schema_id
      end
    end
    context "Field Prototypes" do
      setup do
        @content_class = Class.new(Piece) do
          field :title
          field :synopsis, :string
        end
        @content_class.field :complex, :image, :default => "My default", :comment => "Use this to"
      end

      should "be creatable with just a field name" do
        @content_class.field_prototypes[:title].must_be_instance_of(Spontaneous::Prototypes::FieldPrototype)
        @content_class.field_prototypes[:title].name.should == :title
      end

      should "work with just a name & options" do
        @content_class.field :minimal, :default => "Small"
        @content_class.field_prototypes[:minimal].name.should == :minimal
        @content_class.field_prototypes[:minimal].default.should == "Small"
      end

      should "default to basic string class" do
        assert @content_class.field_prototypes[:title].instance_class < Spontaneous::FieldTypes::StringField
      end

      should "map :string type to FieldTypes::StringField" do
        assert @content_class.field_prototypes[:synopsis].instance_class < Spontaneous::FieldTypes::StringField
      end

      should "be listable" do
        @content_class.field_names.should == [:title, :synopsis, :complex]
      end

      should "be testable for existance" do
        @content_class.field?(:title).should be_true
        @content_class.field?(:synopsis).should be_true
        @content_class.field?(:non_existant).should be_false
        i = @content_class.new
        i.field?(:title).should be_true
        i.field?(:non_existant).should be_false
      end


      context "default values" do
        setup do
          @prototype = @content_class.field_prototypes[:title]
        end


        should "default to a value of ''" do
          @prototype.default.should == ""
        end

        should "get recieve calculated default values if default is a proc" do
          n = 0
          @content_class.field :dynamic, :default => proc { (n += 1) }
          instance = @content_class.new
          instance.dynamic.value.should == "1"
          instance = @content_class.new
          instance.dynamic.value.should == "2"
        end

        should "be able to calculate default values based on properties of owner" do
          @content_class.field :dynamic, :default => proc { |owner| owner.title.value }
          instance = @content_class.new(:title => "Frog")
          instance.dynamic.value.should == "Frog"
        end

        should "match name to type if sensible" do
          content_class = Class.new(Piece) do
            field :image
            field :date
            field :chunky
          end

          assert content_class.field_prototypes[:image].field_class < Spontaneous::FieldTypes::ImageField
          assert content_class.field_prototypes[:date].field_class < Spontaneous::FieldTypes::DateField
          assert content_class.field_prototypes[:chunky].field_class < Spontaneous::FieldTypes::StringField
        end
      end

      context "Field titles" do
        setup do
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

        should "default to a sensible title" do
          @title.title.should == "Title"
          @having_fun.title.should == "Having Fun Yet"
          @synopsis.title.should == "Custom Title"
          @description.title.should == "Simple Description"
        end
      end
      context "option parsing" do
        setup do
          @prototype = @content_class.field_prototypes[:complex]
        end

        should "parse field class" do
          assert @prototype.field_class < Spontaneous::FieldTypes::ImageField
        end

        should "parse default value" do
          @prototype.default.should == "My default"
        end

        should "parse ui comment" do
          @prototype.comment.should == "Use this to"
        end
      end

      context "sub-classes" do
        setup do
          @subclass = Class.new(@content_class) do
            field :child_field
          end
          @subsubclass = Class.new(@subclass) do
            field :distant_relation
          end
        end

        should "inherit super class's field prototypes" do
          @subclass.field_names.should == [:title, :synopsis, :complex, :child_field]
          @subsubclass.field_names.should == [:title, :synopsis, :complex, :child_field, :distant_relation]
        end

        should "deal intelligently with manual setting of field order" do
          @reordered_class = Class.new(@subsubclass) do
            field_order :child_field, :complex
          end
          @reordered_class.field_names.should == [:child_field, :complex, :title, :synopsis, :distant_relation]
        end
      end
    end

    context "Values" do
      setup do
        @field_class = Class.new(FieldTypes::Field) do
          def outputs
            [:html, :plain, :fancy]
          end
          def generate_html(value)
            "<#{value}>"
          end
          def generate_plain(value)
            "*#{value}*"
          end

          def generate(output, value)
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

      should "be transformed by the update method" do
        @field.value = "Hello"
        @field.value.should == "<Hello>"
        @field.value(:html).should == "<Hello>"
        @field.value(:plain).should == "*Hello*"
        @field.value(:fancy).should == "Hello!"
        @field.unprocessed_value.should == "Hello"
      end

      should "appear in the to_s method" do
        @field.value = "String"
        @field.to_s.should == "<String>"
        @field.to_s(:html).should == "<String>"
        @field.to_s(:plain).should == "*String*"
      end

      should "escape ampersands by default" do
        field_class = Class.new(FieldTypes::StringField) do
        end
        field = field_class.new
        field.value = "Hello & Welcome"
        field.value(:html).should == "Hello &amp; Welcome"
        field.value(:plain).should == "Hello & Welcome"
      end

      should "educate quotes" do
        field_class = Class.new(FieldTypes::StringField)
        field = field_class.new
        field.value = %("John's first... example")
        field.value(:html).should == "“John’s first… example”"
        field.value(:plain).should == "“John’s first… example”"
      end

      should "not process values coming from db" do
        class ContentClass1 < Piece
        end
        $transform = lambda { |value| "<#{value}>" }
        ContentClass1.field :title do
          def generate_html(value)
            $transform[value]
          end
        end
        instance = ContentClass1.new
        instance.fields.title = "Monkey"
        instance.save

        $transform = lambda { |value| "*#{value}*" }
        instance = ContentClass1[instance.id]
        instance.fields.title.value.should == "<Monkey>"
        FieldsTest.send(:remove_const, :ContentClass1)
      end
    end

    context "field instances" do
      setup do
        ::CC = Class.new(Piece) do
          field :title, :default => "Magic" do
            def generate_html(value)
              "*#{value}*"
            end
          end
        end
        @instance = CC.new
      end

      teardown do
        Object.send(:remove_const, :CC)
      end

      should "have a link back to their owner" do
        @instance.fields.title.owner.should == @instance
      end

      should "be created with the right default value" do
        f = @instance.fields.title
        f.value.should == "*Magic*"
      end

      should "eval blocks from prototype defn" do
        f = @instance.fields.title
        f.value = "Boo"
        f.value.should == "*Boo*"
        f.unprocessed_value.should == "Boo"
      end

      should "have a reference to their prototype" do
        f = @instance.fields.title
        f.prototype.should == CC.field_prototypes[:title]
      end

      should "return the item which isnt empty when using the / method" do
        a = CC.new(:title => "")
        b = CC.new(:title => "b")
        (a.title / b.title).should == b.title
        a.title = "a"
        (a.title / b.title).should == a.title
      end

      should "return the item which isnt empty when using the | method" do
        a = CC.new(:title => "")
        b = CC.new(:title => "b")
        (a.title | b.title).should == b.title
        a.title = "a"
        (a.title | b.title).should == a.title
      end

      should "return the item which isnt empty when using the or method" do
        a = CC.new(:title => "")
        b = CC.new(:title => "b")
        (a.title.or(b.title)).should == b.title
        a.title = "a"
        (a.title.or(b.title)).should == a.title
      end

    end

    context "Field value persistence" do
      setup do
        class ::PersistedField < Piece
          field :title, :default => "Magic"
        end
      end
      teardown do
        Object.send(:remove_const, :PersistedField)
      end

      should "work" do
        instance = ::PersistedField.new
        instance.fields.title.value = "Changed"
        instance.save
        id = instance.id
        instance = ::PersistedField[id]
        instance.fields.title.value.should == "Changed"
      end
    end

    context "Value version" do
      setup do
        class ::PersistedField < Piece
          field :title, :default => "Magic"
        end
      end
      teardown do
        Object.send(:remove_const, :PersistedField)
      end

      should "be increased after a change" do
        instance = ::PersistedField.new
        instance.fields.title.version.should == 0
        instance.fields.title.value = "Changed"
        instance.save
        instance = ::PersistedField[instance.id]
        instance.fields.title.value.should == "Changed"
        instance.fields.title.version.should == 1
      end

      should "not be increased if the value remains constant" do
        instance = ::PersistedField.new
        instance.fields.title.version.should == 0
        instance.fields.title.value = "Changed"
        instance.save
        instance = ::PersistedField[instance.id]
        instance.fields.title.value = "Changed"
        instance.save
        instance = ::PersistedField[instance.id]
        instance.fields.title.value.should == "Changed"
        instance.fields.title.version.should == 1
        instance.fields.title.value = "Changed!"
        instance.save
        instance = ::PersistedField[instance.id]
        instance.fields.title.version.should == 2
      end
    end

    context "Available output formats" do
      should "include HTML & PDF and default to default value" do
        f = FieldTypes::Field.new
        f.value = "Value"
        f.to_html.should == "Value"
        f.to_pdf.should == "Value"
      end
    end

    context "Markdown fields" do
      setup do
        class ::MarkdownContent < Piece
          field :text1, :markdown
          field :text2, :text
        end
        @instance = MarkdownContent.new
      end
      teardown do
        Object.send(:remove_const, :MarkdownContent)
      end

      should "be available as the :markdown type" do
        assert MarkdownContent.field_prototypes[:text1].field_class < Spontaneous::FieldTypes::MarkdownField
      end
      should "be available as the :text type" do
        assert MarkdownContent.field_prototypes[:text2].field_class < Spontaneous::FieldTypes::MarkdownField
      end

      should "process input into HTML" do
        @instance.text1 = "*Hello* **World**"
        @instance.text1.value.should == "<p><em>Hello</em> <strong>World</strong></p>\n"
      end

      should "use more sensible linebreaks" do
        @instance.text1 = "With\nLinebreak"
        @instance.text1.value.should == "<p>With<br />\nLinebreak</p>\n"
        @instance.text2 = "With  \nLinebreak"
        @instance.text2.value.should == "<p>With<br />\nLinebreak</p>\n"
      end
    end

    context "Editor classes" do
      should "be defined in base types" do
        base_class = Spontaneous::FieldTypes::ImageField
        base_class.editor_class.should == "Spontaneous.FieldTypes.ImageField"
        base_class = Spontaneous::FieldTypes::DateField
        base_class.editor_class.should == "Spontaneous.FieldTypes.DateField"
        base_class = Spontaneous::FieldTypes::MarkdownField
        base_class.editor_class.should == "Spontaneous.FieldTypes.MarkdownField"
        base_class = Spontaneous::FieldTypes::StringField
        base_class.editor_class.should == "Spontaneous.FieldTypes.StringField"
      end

      should "be inherited in subclasses" do
        base_class = Spontaneous::FieldTypes::ImageField
        @field_class = Class.new(base_class)
        @field_class.stubs(:name).returns("CustomField")
        @field_class.editor_class.should == base_class.editor_class
        @field_class2 = Class.new(@field_class)
        @field_class2.stubs(:name).returns("CustomField2")
        @field_class2.editor_class.should == base_class.editor_class
      end
      should "correctly defined by field prototypes" do
        base_class = Spontaneous::FieldTypes::ImageField
        class ::CustomField < Spontaneous::FieldTypes::ImageField
          self.register(:custom)
        end

        class ::CustomContent < Spontaneous::Piece
          field :custom
        end
        assert CustomContent.fields.custom.instance_class < CustomField

        CustomContent.fields.custom.instance_class.editor_class.should == Spontaneous::FieldTypes::ImageField.editor_class

        Object.send(:remove_const, :CustomContent)
        Object.send(:remove_const, :CustomField)
      end
    end

    context "Field versions xxx" do
      setup do
        @user = Spontaneous::Permissions::User.create(:email => "user@example.com", :login => "user", :name => "user", :password => "rootpass", :password_confirmation => "rootpass")
        @user.reload

        class ::Piece
          field :title
        end
        # @content_class.stubs(:name).returns("ContentClass")
        @instance = ::Piece.create
      end

      teardown do
        # Object.send(:remove_const, :Piece) rescue nil
        Spontaneous::Permissions::User.delete
        S::Content.delete
        S::FieldVersion.delete
      end

      should "start out as empty" do
        assert @instance.title.versions.empty?, "Field version list should be empty"
      end

      should "be created every time a field is modified" do
        @instance.title.value = "one"
        @instance.save.reload
        v = @instance.title.versions
        v.count.should == 1
      end

      should "have a creation date" do
        now = Time.now + 1000
        stub_time(now)
        @instance.title.value = "one"
        @instance.save.reload
        @instance.reload
        vv = @instance.title.versions
        v = vv.first
        v.created_at.should == now
      end

      should "save the previous value" do
        @instance.title.value = "one"
        @instance.save.reload
        vv = @instance.title.versions
        v = vv.first
        v.value.should == ""
        @instance.title.value = "two"
        @instance.save.reload
        vv = @instance.title.versions
        v = vv.first
        v.value.should == "one"
        @instance.title.value = "three"
        @instance.save.reload
        vv = @instance.title.versions
        v = vv.first
        v.value.should == "two"
      end

      should "keep a track of the version number" do
        @instance.title.value = "one"
        @instance.save.reload
        vv = @instance.title.versions
        v = vv.first
        v.version.should == 1
        @instance.title.value = "two"
        @instance.save.reload
        vv = @instance.title.versions
        vv.count.should == 2
        v = vv.first
        v.version.should == 2
      end

      should "remember the responsible editor" do
        @instance.current_editor = @user
        @instance.title.value = "one"
        @instance.save.reload
        vv = @instance.title.versions
        v = vv.first
        v.user.should == @user
      end

      should "have quick access to the last version" do
        @instance.title.value = "one"
        @instance.save.reload
        vv = @instance.title.versions
        v = vv.first
        v.value.should == ""
        @instance.title.value = "two"
        @instance.save.reload
        vv = @instance.title.versions
        v = vv.first
        v.value.should == "one"
        @instance.title.previous_version.value.should == "one"
      end
    end

    context "WebVideo fields" do
      setup do
        @content_class = Class.new(::Piece) do
          field :video, :webvideo
        end
        @content_class.stubs(:name).returns("ContentClass")
        @instance = @content_class.new
      end

      should "have their own editor type" do
        @content_class.fields.video.export(nil)[:type].should == "Spontaneous.FieldTypes.WebVideoField"
        @instance.video = "http://www.youtube.com/watch?v=_0jroAM_pO4&feature=feedrec_grec_index"
        fields  = @instance.export(nil)[:fields]
        fields[0][:processed_value].should == @instance.video.src
      end

      should "recognise youtube URLs" do
        @instance.video = "http://www.youtube.com/watch?v=_0jroAM_pO4&feature=feedrec_grec_index"
        @instance.video.value.should == "http://www.youtube.com/watch?v=_0jroAM_pO4&amp;feature=feedrec_grec_index"
        @instance.video.id.should == "_0jroAM_pO4"
        @instance.video.video_type.should == "youtube"
      end

      should "recognise Vimeo URLs" do
        @instance.video = "http://vimeo.com/31836285"
        @instance.video.value.should == "http://vimeo.com/31836285"
        @instance.video.id.should == "31836285"
        @instance.video.video_type.should == "vimeo"
      end

      context "with player settings" do
        setup do
          @content_class.field :video2, :webvideo, :player => {
            :width => 680, :height => 384,
            :fullscreen => true, :autoplay => true, :loop => true,
            :showinfo => false,
            :youtube => { :theme => 'light', :hd => true, :controls => false },
            :vimeo => { :color => "ccc", :api => true }
          }
          @instance = @content_class.new
          @field = @instance.video2
        end

        should "use the configuration in the youtube player HTML" do
          @field.value = "http://www.youtube.com/watch?v=_0jroAM_pO4&feature=feedrec_grec_index"
          html = @field.render(:html)
          html.should =~ /^<iframe/
          html.should =~ %r{src="http://www\.youtube\.com/embed/_0jroAM_pO4}
          html.should =~ /width="680"/
          html.should =~ /height="384"/
          html.should =~ /theme=light/
          html.should =~ /hd=1/
          html.should =~ /fs=1/
          html.should =~ /controls=0/
          html.should =~ /autoplay=1/
          html.should =~ /showinfo=0/
          html.should =~ /showsearch=0/
          @field.render(:html, :youtube => {:showsearch => 1}).should =~ /showsearch=1/
          @field.render(:html, :youtube => {:theme => 'dark'}).should =~ /theme=dark/
          @field.render(:html, :width => 100).should =~ /width="100"/
          @field.render(:html, :loop => true).should =~ /loop=1/
        end

        should "use the configuration in the Vimeo player HTML" do
          @field.value = "http://vimeo.com/31836285"
          html = @field.render(:html)
          html.should =~ /^<iframe/
          html.should =~ %r{src="http://player\.vimeo\.com/video/31836285}
          html.should =~ /width="680"/
          html.should =~ /height="384"/
          html.should =~ /color=ccc/
          html.should =~ /webkitAllowFullScreen="yes"/
          html.should =~ /allowFullScreen="yes"/
          html.should =~ /autoplay=1/
          html.should =~ /title=0/
          html.should =~ /byline=0/
          html.should =~ /portrait=0/
          html.should =~ /api=1/
          @field.render(:html, :vimeo => {:color => 'f0abcd'}).should =~ /color=f0abcd/
          @field.render(:html, :loop => true).should =~ /loop=1/
          @field.render(:html, :title => true).should =~ /title=1/
          @field.render(:html, :title => true).should =~ /byline=0/
        end

        should "provide a version of the YouTube player params in JSON/JS format" do
          @field.value = "http://www.youtube.com/watch?v=_0jroAM_pO4&feature=feedrec_grec_index"
          json = JSON.parse(@field.render(:json))
          json[:"tagname"].should == "iframe"
          json[:"tag"].should == "<iframe/>"
          attr = json[:"attr"]
          attr.must_be_instance_of(Hash)
          attr[:"src"].should =~ %r{^http://www\.youtube\.com/embed/_0jroAM_pO4}
          attr[:"src"].should =~ /theme=light/
          attr[:"src"].should =~ /hd=1/
          attr[:"src"].should =~ /fs=1/
          attr[:"src"].should =~ /controls=0/
          attr[:"src"].should =~ /autoplay=1/
          attr[:"src"].should =~ /showinfo=0/
          attr[:"src"].should =~ /showsearch=0/
          attr[:"width"].should == 680
          attr[:"height"].should == 384
          attr[:"frameborder"].should == "0"
          attr[:"type"].should == "text/html"
        end

        should "provide a version of the Vimeo player params in JSON/JS format" do
          @field.value = "http://vimeo.com/31836285"
          json = JSON.parse(@field.render(:json))
          json[:"tagname"].should == "iframe"
          json[:"tag"].should == "<iframe/>"
          attr = json[:"attr"]
          attr.must_be_instance_of(Hash)
          attr[:"src"].should =~ /color=ccc/
          attr[:"src"].should =~ /autoplay=1/
          attr[:"src"].should =~ /title=0/
          attr[:"src"].should =~ /byline=0/
          attr[:"src"].should =~ /portrait=0/
          attr[:"src"].should =~ /api=1/
          attr[:"webkitAllowFullScreen"].should == "yes"
          attr[:"allowFullScreen"].should == "yes"
          attr[:"width"].should == 680
          attr[:"height"].should == 384
          attr[:"frameborder"].should == "0"
          attr[:"type"].should == "text/html"
        end


        should "use the YouTube api to extract video metadata" do
          youtube_info = {"thumbnail_large" => "http://i.ytimg.com/vi/_0jroAM_pO4/hqdefault.jpg", "thumbnail_small"=>"http://i.ytimg.com/vi/_0jroAM_pO4/default.jpg", "title" => "Hilarious QI Moment - Cricket", "description" => "Rob Brydon makes a rather embarassing choice of words whilst discussing the relationship between a cricket's chirping and the temperature. Taken from QI XL Series H episode 11 - Highs and Lows", "user_name" => "morthasa", "upload_date" => "2011-01-14 19:49:44", "tags" => "Hilarious, QI, Moment, Cricket, fun, 11, stephen, fry, alan, davies, Rob, Brydon, SeriesH, Fred, MacAulay, Sandi, Toksvig", "duration" => 78, "stats_number_of_likes" => 297, "stats_number_of_plays" => 53295, "stats_number_of_comments" => 46}#.symbolize_keys

          response_xml_file = File.expand_path("../../fixtures/fields/youtube_api_response.xml", __FILE__)
          connection = mock()
          @field.expects(:open).with("http://gdata.youtube.com/feeds/api/videos/_0jroAM_pO4?v=2").returns(connection)
          doc = Nokogiri::XML(File.open(response_xml_file))
          Nokogiri.expects(:XML).with(connection).returns(doc)
          @field.value = "http://www.youtube.com/watch?v=_0jroAM_pO4"
          @field.values.should == youtube_info.merge(:id => "_0jroAM_pO4", :type => "youtube", :html => "http://www.youtube.com/watch?v=_0jroAM_pO4")
        end

        should "use the Vimeo api to extract video metadata" do
          vimeo_info = {"id"=>29987529, "title"=>"Neon Indian Plays The UO Music Shop", "description"=>"Neon Indian plays electronic instruments from the UO Music Shop, Fall 2011. Read more at blog.urbanoutfitters.com.", "url"=>"http://vimeo.com/29987529", "upload_date"=>"2011-10-03 18:32:47", "mobile_url"=>"http://vimeo.com/m/29987529", "thumbnail_small"=>"http://b.vimeocdn.com/ts/203/565/203565974_100.jpg", "thumbnail_medium"=>"http://b.vimeocdn.com/ts/203/565/203565974_200.jpg", "thumbnail_large"=>"http://b.vimeocdn.com/ts/203/565/203565974_640.jpg", "user_name"=>"Urban Outfitters", "user_url"=>"http://vimeo.com/urbanoutfitters", "user_portrait_small"=>"http://b.vimeocdn.com/ps/251/111/2511118_30.jpg", "user_portrait_medium"=>"http://b.vimeocdn.com/ps/251/111/2511118_75.jpg", "user_portrait_large"=>"http://b.vimeocdn.com/ps/251/111/2511118_100.jpg", "user_portrait_huge"=>"http://b.vimeocdn.com/ps/251/111/2511118_300.jpg", "stats_number_of_likes"=>85, "stats_number_of_plays"=>26633, "stats_number_of_comments"=>0, "duration"=>100, "width"=>640, "height"=>360, "tags"=>"neon indian, analog, korg, moog, theremin, micropiano, microkorg, kaossilator, kaossilator pro", "embed_privacy"=>"anywhere"}.symbolize_keys
          connection = mock()
          connection.expects(:read).returns(Spontaneous.encode_json([vimeo_info]))
          @field.expects(:open).with("http://vimeo.com/api/v2/video/29987529.json").returns(connection)
          @field.value = "http://vimeo.com/29987529"
          @field.values.should == vimeo_info.merge(:id => "29987529", :type => "vimeo", :html => "http://vimeo.com/29987529")
        end
      end

    end

    context "Location fields" do
      setup do
        @content_class = Class.new(::Piece) do
          field :location
        end
        @content_class.stubs(:name).returns("ContentClass")
        @instance = @content_class.new
        @field = @instance.location
      end

      should "use a standard string editor" do
        @content_class.fields.location.export(nil)[:type].should == "Spontaneous.FieldTypes.StringField"
      end

      should "successfullt geolocate an address" do
        @field.value = "Cambridge, England"
        @field.value(:lat).should == 52.2053370
        @field.value(:lng).should == 0.1218170
        @field.value(:country).should == "United Kingdom"
        @field.value(:formatted_address).should == "Cambridge, UK"

        @field.latitude.should == 52.2053370
        @field.longitude.should == 0.1218170
        @field.lat.should == 52.2053370
        @field.lng.should == 0.1218170

        @field.country.should == "United Kingdom"
        @field.formatted_address.should == "Cambridge, UK"
      end
    end

    context "Option fields" do
      setup do
        @content_class = Class.new(::Piece) do
          field :options, :select, :options => [
            ["a", "Value A"],
            ["b", "Value B"],
            ["c", "Value C"]
          ]
        end
        @content_class.stubs(:name).returns("ContentClass")
        @instance = @content_class.new
        @field = @instance.options
      end

      should "use a specific editor class" do
        @content_class.fields.options.export(nil)[:type].should == "Spontaneous.FieldTypes.SelectField"
      end

      should "select the options class for fields named options" do
        @content_class.field :type, :select, :options => [["a", "A"]]
        assert @content_class.fields.options.instance_class.ancestors.include?(Spontaneous::FieldTypes::SelectField)
      end

      should "accept a list of strings as options" do
        @content_class.field :type, :select, :options => ["a", "b"]
        @instance = @content_class.new
        @instance.type.option_list.should == [["a", "a"], ["b", "b"]]
      end

      should "accept a json string as a value and convert it properly" do
        @field.value = %(["a", "Value A"])
        @field.value.should == "a"
        @field.value(:label).should == "Value A"
        @field.label.should == "Value A"
        @field.unprocessed_value.should == %(["a", "Value A"])
      end
    end

    context "File fields" do
      setup do
        @content_class = Class.new(::Piece)
        @prototype = @content_class.field :file
        @content_class.stubs(:name).returns("ContentClass")
        @instance = @content_class.create
        @field = @instance.file
      end

      should "have a distinct editor class" do
        @prototype.instance_class.editor_class.should == "Spontaneous.FieldTypes.FileField"
      end

      should "adopt any field called 'file'" do
        assert @field.is_a?(Spontaneous::FieldTypes::FileField), "Field should be an instance of FileField but instead has the following ancestors #{ @prototype.instance_class.ancestors }"
      end

      should "copy files to the media folder" do
        path = File.expand_path("../../fixtures/images/vimlogo.pdf", __FILE__)
        assert File.exists?(path), "Test file #{path} does not exist"
        File.open(path, 'rb') do |file|
          @field.value = {
            :tempfile => file,
            :type => "application/pdf",
            :filename => "vimlogo.pdf"
          }
        end
        url = @field.value
        path = File.join File.dirname(Spontaneous.media_dir), url
        assert File.exist?(path), "Media file should have been copied into place"
      end

      should "generate the requisite file metadata" do
        path = File.expand_path("../../fixtures/images/vimlogo.pdf", __FILE__)
        assert File.exists?(path), "Test file #{path} does not exist"
        File.open(path, 'rb') do |file|
          @field.value = {
            :tempfile => file,
            :type => "application/pdf",
            :filename => "vimlogo.pdf"
          }
        end
        @field.value(:html).should =~ %r{/media/.+/vimlogo.pdf$}
        @field.value.should =~ %r{/media/.+/vimlogo.pdf$}
        @field.path.should == @field.value
        @field.value(:filesize).should == 2254
        @field.filesize.should == 2254
        @field.value(:filename).should == "vimlogo.pdf"
        @field.filename.should == "vimlogo.pdf"
      end

      should "just accept the given value if passed a path to a non-existant file" do
        @field.value = "/images/nosuchfile.rtf"
        @field.value.should ==  "/images/nosuchfile.rtf"
        @field.filename.should == "nosuchfile.rtf"
        @field.filesize.should == 0
      end

      should "copy the given file if passed a path to an existing file" do
        path = File.expand_path("../../fixtures/images/vimlogo.pdf", __FILE__)
        @field.value = path
        @field.value.should =~ %r{/media/.+/vimlogo.pdf$}
        @field.filename.should == "vimlogo.pdf"
        @field.filesize.should == 2254
      end
    end
    context "Date fields" do
      setup do
        @content_class = Class.new(::Piece)
        @prototype = @content_class.field :date
        @content_class.stubs(:name).returns("ContentClass")
        @instance = @content_class.create
        @field = @instance.date
      end

      should "have a distinct editor class" do
        @prototype.instance_class.editor_class.should == "Spontaneous.FieldTypes.DateField"
      end

      should "adopt any field called 'date'" do
        assert @field.is_a?(Spontaneous::FieldTypes::DateField), "Field should be an instance of DateField but instead has the following ancestors #{ @prototype.instance_class.ancestors }"
      end

      should "default to an empty string" do
        @field.value(:html).should == ""
        @field.value(:plain).should == ""
      end

      should "correctly parse strings" do
        @field.value = "Friday, 8 June, 2012"
        @field.value(:html).should == %(<time datetime="2012-06-08">Friday, 8 June, 2012</time>)
        @field.value(:plain).should == %(Friday, 8 June, 2012)
        @field.date.should == Date.parse("Friday, 8 June, 2012")
      end

      should "allow for setting a custom default format" do
        prototype = @content_class.field :datef, :date, :format => "%d %b %Y, %a"
        instance = @content_class.new
        field = instance.datef
        field.value = "Friday, 8 June, 2012"
        field.value(:html).should == %(<time datetime="2012-06-08">08 Jun 2012, Fri</time>)
        field.value(:plain).should == %(08 Jun 2012, Fri)
      end
    end
  end
end

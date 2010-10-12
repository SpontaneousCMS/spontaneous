require 'test_helper'

class FieldsTest < Test::Unit::TestCase
  include Spontaneous

  context "New content instances" do
    setup do
      @content_class = Class.new(Content) do
        field :title, :default_value => "Magic"
        field :thumbnail, :image
      end
      @instance = @content_class.new
    end

    should "have fields with values defined by prototypes" do
      f = @instance.fields[:title]
      f.class.should == Spontaneous::FieldTypes::StringField
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

  context "Field Prototypes" do
    setup do
      @content_class = Class.new(Content) do
        field :title
        field :synopsis, :string
      end
      @content_class.field :complex, :image, :default_value => "My default", :comment => "Use this to"
    end

    should "be creatable with just a field name" do
      @content_class.field_prototypes[:title].should be_instance_of Spontaneous::FieldPrototype
      @content_class.field_prototypes[:title].name.should == :title
    end

    should "map :string type to FieldTypes::Text" do
      @content_class.field_prototypes[:synopsis].field_class.should == Spontaneous::FieldTypes::StringField
    end

    should "be listable" do
      @content_class.field_names.should == [:title, :synopsis, :complex]
    end

    context "default values" do
      setup do
        @prototype = @content_class.field_prototypes[:title]
      end

      should "default to basic string class" do
        @prototype.field_class.should == Spontaneous::FieldTypes::StringField
      end

      should "default to a value of ''" do
        @prototype.default_value.should == ""
      end

    end

    context "Field titles" do
      setup do
        @content_class = Class.new(Content) do
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
        @prototype.field_class.should == Spontaneous::FieldTypes::ImageField
      end

      should "parse default value" do
        @prototype.default_value.should == "My default"
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
      @field_class = Class.new(Field) do
        def process(value)
          "<#{value}>"
        end
      end
      @field = @field_class.new()
    end

    should "be transformed by the update method" do
      @field.value = "Hello"
      @field.value.should == "<Hello>"
      @field.unprocessed_value.should == "Hello"
    end

    should "appear in the to_s method" do
      @field.value = "String"
      @field.to_s.should == "<String>"
    end

    should "not process values coming from db" do
      content_class = Class.new(Content)
      content_class.field :title do
        def process(value)
          "<#{value}>"
        end
      end
      instance = content_class.new
      instance.fields.title = "Monkey"
      instance.save

      new_content_class = Class.new(Content)
      new_content_class.field :title do
        def process(value)
          "*#{value}*"
        end
      end
      instance = new_content_class[instance.id]
      instance.fields.title.value.should == "<Monkey>"
    end
  end

  context "field instances" do
    setup do
      ::CC = Class.new(Content) do
        field :title, :default_value => "Magic" do
          def process(value)
            "*#{value}*"
          end
        end
      end
      @instance = CC.new
    end

    teardown do
      Object.send(:remove_const, :CC)
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
  end

  context "Field value persistence" do
    setup do
      class ::PersistedField < Content
        field :title, :default_value => "Magic"
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
end

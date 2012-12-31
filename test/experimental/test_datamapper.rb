# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'sequel'

class DataMapperTest < MiniTest::Spec
  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  class NameMap
    def initialize(*args)
    end

    def to_id(klass)
      klass.to_s
    end

    def to_class(sid)
      sid.to_s.constantize
    end
  end

  context "datamapper" do
    setup do
      @now = Spontaneous::DataMapper.timestamp
      @expected_columns = [:id, :type_sid, :label, :object1, :object2]
      @database = ::Sequel.mock(autoid: 1)
      @table = Spontaneous::DataMapper::ContentTable.new(:content, @database)
      @schema = Spontaneous::Schema.new(Dir.pwd, NameMap)
      @mapper = Spontaneous::DataMapper.new(@table, @schema)
      @database.columns = @expected_columns
      Spontaneous::DataMapper.stubs(:timestamp).returns(@now)
      MockContent = Spontaneous::DataMapper::Model(:content, @database, @schema) do
        serialize_columns :object1, :object2
      end
      # having timestamps on makes testing the sql very difficult/tedious
      MockContent2 = Class.new(MockContent)
      @database.sqls # clear sql log -- column introspection makes a query to the db
    end

    teardown do
      DataMapperTest.send :remove_const, :MockContent rescue nil
      DataMapperTest.send :remove_const, :MockContent2 rescue nil
    end

    should "be creatable from any table" do
      table = Spontaneous::DataMapper::ContentTable.new(:content, @database)
      mapper = Spontaneous::DataMapper.new(table, @schema)
      mapper.must_be_instance_of Spontaneous::DataMapper::ScopingMapper
    end

    context "instances" do
      should "insert model data when saving a new model instance" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.new(:label => "column1")
        instance.new?.should be_true
        @mapper.create(instance)
        @database.sqls.should == [
          "INSERT INTO content (label, type_sid) VALUES ('column1', 'DataMapperTest::MockContent')",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1"
        ]
        instance.new?.should be_false
        instance.id.should == 1
      end

      should "insert models using the DataMapper.create method" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        instance = @mapper.instance MockContent, :label => "column1"
        @database.sqls.should == [
          "INSERT INTO content (label, type_sid) VALUES ('column1', 'DataMapperTest::MockContent')",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1"
        ]
        instance.new?.should be_false
        instance.id.should == 1
      end

      should "update an existing model" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        instance = @mapper.instance MockContent, :label => "column1"
        instance.set label: "changed"
        @mapper.save(instance)
        @database.sqls.should == [
          "INSERT INTO content (label, type_sid) VALUES ('column1', 'DataMapperTest::MockContent')",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1",
          "UPDATE content SET label = 'changed' WHERE (id = 1)"
        ]
      end

      should "update model rows directly" do
        @mapper.update([MockContent], label: "changed")
        @database.sqls.should == [
          "UPDATE content SET label = 'changed' WHERE (type_sid IN ('DataMapperTest::MockContent'))"
        ]
      end

      should "find an existing model" do
        instance = @mapper.instance MockContent, :label => "column1"
        @database.sqls # clear the sql log
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        instance = @mapper.get(1)
        @database.sqls.should == [
          "SELECT * FROM content WHERE (id = 1) LIMIT 1"
        ]
        instance.must_be_instance_of MockContent
        instance.id.should == 1
        instance.attributes[:label].should == "column1"
      end

      should "allow for finding the first instance of a model" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        instance = @mapper.first([MockContent], id: 1)
        @database.sqls.should == [
          "SELECT * FROM content WHERE ((type_sid IN ('DataMapperTest::MockContent')) AND (id = 1)) LIMIT 1"
        ]
      end

      should "be scopable to a revision" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        @mapper.revision(10) do
          instance = @mapper.instance MockContent, :label => "column1"
          instance.set label: "changed"
          @mapper.save(instance)
          @database.sqls.should == [
            "INSERT INTO __r00010_content (label, type_sid) VALUES ('column1', 'DataMapperTest::MockContent')",
            "SELECT * FROM __r00010_content WHERE (id = 1) LIMIT 1",
            "UPDATE __r00010_content SET label = 'changed' WHERE (id = 1)"
          ]
        end
      end

      should "allow for retrieval of rows from a specific revision" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        instance = @mapper.revision(20).get(1)
        @database.sqls.should == ["SELECT * FROM __r00020_content WHERE (id = 1) LIMIT 1"]
        instance.must_be_instance_of MockContent
        instance.id.should == 1
        instance.attributes[:label].should == "column1"
      end

      should "support nested revision scopes" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        @mapper.revision(10) do
          instance = @mapper.get(1)
          instance.label = "changed1"
          @mapper.save(instance)
          @mapper.revision(20) do
            instance = @mapper.get(1)
            instance.label = "changed2"
            @mapper.save(instance)
            instance = @mapper.editable.get(3)
          end
        end
        @database.sqls.should == [
          "SELECT * FROM __r00010_content WHERE (id = 1) LIMIT 1",
          "UPDATE __r00010_content SET label = 'changed1' WHERE (id = 1)",
          "SELECT * FROM __r00020_content WHERE (id = 1) LIMIT 1",
          "UPDATE __r00020_content SET label = 'changed2' WHERE (id = 1)",
          "SELECT * FROM content WHERE (id = 3) LIMIT 1"
        ]
      end

      should "allow for finding all instances of a class with DataMapper#all" do
        @database.fetch = [
          { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" },
          { id:2, label:"column2", type_sid:"DataMapperTest::MockContent2" }
        ]
        results = @mapper.all([MockContent, MockContent2])
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('DataMapperTest::MockContent', 'DataMapperTest::MockContent2'))"
        ]
        results.map(&:class).should == [MockContent, MockContent2]
        results.map(&:id).should == [1, 2]
      end

      should "allow for finding all instances of a class with DataMapper#types" do
        @database.fetch = [
          { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" },
          { id:2, label:"column2", type_sid:"DataMapperTest::MockContent2" }
        ]
        results = @mapper.all([MockContent, MockContent2])
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('DataMapperTest::MockContent', 'DataMapperTest::MockContent2'))"
        ]
        results.map(&:class).should == [MockContent, MockContent2]
        results.map(&:id).should == [1, 2]
      end

      should "allow for counting type rows" do
        @mapper.count([MockContent, MockContent2])
        @database.sqls.should == [
          "SELECT COUNT(*) AS count FROM content WHERE (type_sid IN ('DataMapperTest::MockContent', 'DataMapperTest::MockContent2')) LIMIT 1"
        ]
      end

      should "allow for use of block iterator when loading all model instances" do
        ids = []
        @database.fetch = [
          { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" },
          { id:2, label:"column2", type_sid:"DataMapperTest::MockContent2" }
        ]
        results = @mapper.all([MockContent, MockContent2]) do |i|
          ids << i.id
        end
        ids.should == [1, 2]
        results.map(&:class).should == [MockContent, MockContent2]
      end

      should "allow for defining an order" do
        ds = @mapper.order([MockContent], "column1").all
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('DataMapperTest::MockContent')) ORDER BY 'column1'"
        ]
      end

      should "support chained filters" do
        @database.fetch = [
          { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        ]
        ds = @mapper.filter([MockContent, MockContent2], id:1)
        results = ds.all
        results.map(&:class).should == [MockContent]
        results.map(&:id).should == [1]
        @database.sqls.should == [
          "SELECT * FROM content WHERE ((type_sid IN ('DataMapperTest::MockContent', 'DataMapperTest::MockContent2')) AND (id = 1))"
        ]
      end

      should "support filtering using virtual rows" do
        @database.fetch = [
          { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" },
          { id:2, label:"column2", type_sid:"DataMapperTest::MockContent2" }
        ]
        ds = @mapper.filter([MockContent, MockContent2]) { id > 0 }
        results = ds.all
        results.map(&:class).should == [MockContent, MockContent2]
        results.map(&:id).should == [1, 2]
        @database.sqls.should == [
          "SELECT * FROM content WHERE ((type_sid IN ('DataMapperTest::MockContent', 'DataMapperTest::MockContent2')) AND (id > 0))"
        ]
      end

      should "support multiple concurrent filters" do
        # want to be sure that each dataset is independent
        ds1 = @mapper.filter([MockContent], id: 1)
        ds2 = @mapper.filter([MockContent2])

        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        ds1.first([]).must_be_instance_of MockContent

        @database.fetch = { id:2, label:"column2", type_sid:"DataMapperTest::MockContent2" }
        ds2.first([]).must_be_instance_of MockContent2

        @database.sqls.should == [
          "SELECT * FROM content WHERE ((type_sid IN ('DataMapperTest::MockContent')) AND (id = 1)) LIMIT 1",
          "SELECT * FROM content WHERE (type_sid IN ('DataMapperTest::MockContent2')) LIMIT 1"
        ]
      end

      should "allow you to delete datasets" do
        @mapper.delete([MockContent])
        @database.sqls.should == [
          "DELETE FROM content WHERE (type_sid IN ('DataMapperTest::MockContent'))"
        ]
      end

      should "allow you to delete instances" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        instance = @mapper.instance MockContent, label: "label"
        @database.sqls
        @mapper.delete_instance instance
        @database.sqls.should == [
          "DELETE FROM content WHERE (id = 1)"
        ]
      end

      should "allow you to delete instances within a revision" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        instance = @mapper.instance MockContent, label: "label"
        @database.sqls
        @mapper.revision(20) do
          @mapper.delete_instance instance
        end
        @database.sqls.should == [
          "DELETE FROM __r00020_content WHERE (id = 1)"
        ]
      end

      should "allow you to destroy model instances" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        instance = @mapper.instance MockContent, :label => "column1"
        @database.sqls # clear sql log
        @mapper.delete_instance instance
        instance.id.should == 1
        @database.sqls.should == [
          "DELETE FROM content WHERE (id = 1)"
        ]
      end

      should "support visibility contexts" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        @mapper.visible do
          @mapper.get(1)
          @mapper.visible(false) do
            @mapper.get(1)
            @mapper.visible.get(1)
          end
        end
        @database.sqls.should == [
          "SELECT * FROM content WHERE ((hidden IS FALSE) AND (id = 1)) LIMIT 1",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1",
          "SELECT * FROM content WHERE ((hidden IS FALSE) AND (id = 1)) LIMIT 1",
        ]
      end

      should "support mixed revision & visibility states" do
        @database.fetch = { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        @mapper.revision(25) do
          @mapper.visible do
            @mapper.get(1)
          end
        end
        @database.sqls.should == [
          "SELECT * FROM __r00025_content WHERE ((hidden IS FALSE) AND (id = 1)) LIMIT 1",
        ]
      end

      should "ignore visibility filter for deletes" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        instance = @mapper.instance MockContent, label: "label"
        @database.sqls
        @mapper.visible do
          @mapper.delete_instance(instance)
        end
        @database.sqls.should == [
          "DELETE FROM content WHERE (id = 1)",
        ]
      end

      should "ignore visibility setting for creates" do
        @mapper.visible do
          @mapper.revision(99) do
            instance = @mapper.instance MockContent, :label => "column1"
          end
        end
        @database.sqls.should == [
          "INSERT INTO __r00099_content (label, type_sid) VALUES ('column1', 'DataMapperTest::MockContent')",
          "SELECT * FROM __r00099_content WHERE (id = 1) LIMIT 1"
        ]
      end

      should "allow for inserting raw attributes" do
        @mapper.insert type_sid: "MockContent", label: "label"
        @database.sqls.should == [
          "INSERT INTO content (type_sid, label) VALUES ('MockContent', 'label')"
        ]
      end
    end

    context "models" do
      should "be deletable" do
        MockContent.delete
        @database.sqls.should == [
          "DELETE FROM content WHERE (type_sid IN ('DataMapperTest::MockContent'))"
        ]
      end

      should "be creatable using Model.create" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(label: "value")
        @database.sqls.should == [
          "INSERT INTO content (label, type_sid) VALUES ('value', 'DataMapperTest::MockContent')",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1"
        ]
        instance.new?.should be_false
        instance.id.should == 1
      end

      should "be instantiable using Model.new" do
        instance = MockContent.new(label: "value")
        instance.new?.should be_true
      end

      should "be creatable using Model.new" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.new(label: "value")
        instance.save
        instance.new?.should be_false
        @database.sqls.should == [
          "INSERT INTO content (label, type_sid) VALUES ('value', 'DataMapperTest::MockContent')",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1"
        ]
        instance.id.should == 1
      end

      should "be updatable" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(label: "value")
        instance.update(label: "changed")
        @database.sqls.should == [
          "INSERT INTO content (label, type_sid) VALUES ('value', 'DataMapperTest::MockContent')",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1",
          "UPDATE content SET label = 'changed' WHERE (id = 1)"
        ]
      end

      should "exclude id column from updates" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(id: 103, label: "value")
        instance.id.should == 1
        instance.update(id: 99, label: "changed")
        @database.sqls.should == [
          "INSERT INTO content (label, type_sid) VALUES ('value', 'DataMapperTest::MockContent')",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1",
          "UPDATE content SET label = 'changed' WHERE (id = 1)"
        ]
        instance.id.should == 1
      end

      should "exclude type_sid column from updates" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(type_sid: "Nothing", label: "value")
        instance.update(type_sid: "Invalid", label: "changed")
        @database.sqls.should == [
          "INSERT INTO content (label, type_sid) VALUES ('value', 'DataMapperTest::MockContent')",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1",
          "UPDATE content SET label = 'changed' WHERE (id = 1)"
        ]
        instance.id.should == 1
      end

      should "only update changed columns" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(label: "value")
        @database.sqls
        instance.changed_columns.should == []
        instance.label = "changed"
        instance.changed_columns.should == [:label]
        instance.object1 = "updated"
        instance.changed_columns.should == [:label, :object1]
        instance.save
        @database.sqls.should == [
          "UPDATE content SET label = 'changed', object1 = '\"updated\"' WHERE (id = 1)"
        ]
      end

      should "mark new instances as modified" do
        instance = MockContent.new(label: "value")
        instance.modified?.should be_true
      end

      should "updated modified flag after save" do
        instance = MockContent.new(label: "value")
        instance.save
        instance.modified?.should be_false
      end

      should "have a modified flag if columns changed" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(label: "value")
        instance.modified?.should be_false
        instance.label = "changed"
        instance.modified?.should be_true
      end

      should "not make a db call if no values have been modified" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(label: "value")
        @database.sqls
        instance.save
        @database.sqls.should == []
      end

      should "allow you to force a save" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(label: "value")
        @database.sqls
        instance.mark_modified!
        instance.save
        @database.sqls.should == [
          "UPDATE content SET label = 'value', type_sid = 'DataMapperTest::MockContent' WHERE (id = 1)"
        ]
      end

      should "allow you to force an update to a specific column" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(label: "value")
        @database.sqls
        instance.mark_modified!(:label)
        instance.save
        @database.sqls.should == [
          "UPDATE content SET label = 'value' WHERE (id = 1)"
        ]
      end

      should "be destroyable" do
        @database.fetch = { id:1, label:"value", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.create(label: "value")
        instance.id.should == 1
        instance.destroy
        @database.sqls.should == [
          "INSERT INTO content (label, type_sid) VALUES ('value', 'DataMapperTest::MockContent')",
          "SELECT * FROM content WHERE (id = 1) LIMIT 1",
          "DELETE FROM content WHERE (id = 1)"
        ]
      end

      should "allow for searching for all instances of a class" do
        @database.fetch = [
          { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" },
          { id:2, label:"column2", type_sid:"DataMapperTest::MockContent" }
        ]
        results = MockContent.all
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('DataMapperTest::MockContent'))"
        ]
        results.length.should == 2
        results.map(&:class).should == [MockContent, MockContent]
        results.map(&:id).should == [1, 2]
      end

      should "allow for finding first instance of a type" do
        @database.fetch = [
          { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        ]
        instance = MockContent.first
        MockContent.first(id: 1)
        MockContent.first { id > 0}
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('DataMapperTest::MockContent')) LIMIT 1",
          "SELECT * FROM content WHERE ((type_sid IN ('DataMapperTest::MockContent')) AND (id = 1)) LIMIT 1",
          "SELECT * FROM content WHERE ((type_sid IN ('DataMapperTest::MockContent')) AND (id > 0)) LIMIT 1"
        ]
        instance.must_be_instance_of MockContent
        instance.id.should == 1
      end

      should "return nil if no instance matching filter is found" do
        @database.fetch = []
        instance = MockContent.first(id: 1)
        instance.should be_nil
      end

      should "retrieve by primary key using []" do
        instance = MockContent[1]
        @database.sqls.should == [
          "SELECT * FROM content WHERE (id = 1) LIMIT 1",
        ]
      end

      should "have correct equality test" do
        @database.fetch = [
          { id:1, label:"column1", type_sid:"DataMapperTest::MockContent" }
        ]
        a = MockContent[1]
        b = MockContent[1]
        a.should == b

        a.label = "changed"
        a.should_not == b
      end

      should "allow for filtering model instances" do
        @database.fetch = [
          { id:100, label:"column1", type_sid:"DataMapperTest::MockContent" }
        ]
        results = MockContent.filter(hidden: false).all
        @database.sqls.should == [
          "SELECT * FROM content WHERE ((type_sid IN ('DataMapperTest::MockContent')) AND (hidden IS FALSE))"
        ]
        results.length.should == 1
        results.map(&:class).should == [MockContent]
        results.map(&:id).should == [100]
      end

      should "use the current mapper revision to save" do
        @database.fetch = [
          { id:100, label:"column1", type_sid:"DataMapperTest::MockContent" }
        ]
        instance = nil
        @mapper.revision(99) do
          instance = MockContent.first
        end
        instance.update(label: "changed")
        @mapper.revision(99) do
          instance.update(label: "changed2")
        end
        @database.sqls.should == [
          "SELECT * FROM __r00099_content WHERE (type_sid IN ('DataMapperTest::MockContent')) LIMIT 1",
          "UPDATE content SET label = 'changed' WHERE (id = 100)",
          "UPDATE __r00099_content SET label = 'changed2' WHERE (id = 100)"
        ]
      end

      should "allow for reloading values from the db" do
        @database.fetch = { id:100, label:"column1", type_sid:"DataMapperTest::MockContent" }
        instance = MockContent.first
        instance.set(label:"changed")
        instance.attributes[:label].should == "changed"
        instance.changed_columns.should == [:label]
        instance.reload
        instance.attributes[:label].should == "column1"
        instance.changed_columns.should == []
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('DataMapperTest::MockContent')) LIMIT 1",
          "SELECT * FROM content WHERE (id = 100) LIMIT 1"
        ]
      end


      should "update model rows directly" do
        MockContent.update(label: "changed")
        @database.sqls.should == [
          "UPDATE content SET label = 'changed' WHERE (type_sid IN ('DataMapperTest::MockContent'))"
        ]
      end

      should "introspect columns" do
        MockContent.columns.should == @expected_columns
      end

      should "create getters & setters for all columns except id & type_sid" do
        columns = (@expected_columns - [:id, :type_sid])
        attrs = Hash[columns.map { |c| [c, "#{c}_value"] } ]
        c = MockContent.new attrs

        columns.each do |column|
          assert c.respond_to?(column), "Instance should respond to ##{column}"
          assert c.respond_to?("#{column}="), "Instance should respond to ##{column}="
          c.send(column).should == attrs[column]
          c.send("#{column}=", "changed")
          c.send(column).should == "changed"
        end
      end

      should "set values using the setter methods" do
        model = Class.new(MockContent) do
          def label=(value); super(value + "!"); end
        end
        instance = model.new label: "label1"
        instance.set(label: "label2")
        instance.label.should == "label2!"
      end

      should "support after_initialize hooks" do
        model = Class.new(MockContent) do
          attr_accessor :param
          def after_initialize
            self.param = true
          end
        end
        instance = model.new
        instance.param.should be_true
      end

      should "support before create triggers" do
        model = Class.new(MockContent) do
          attr_accessor :param
          def before_create
            self.param = true
          end
        end
        instance = model.create
        instance.param.should be_true
      end

      should "support after create triggers" do
        model = Class.new(MockContent) do
          attr_accessor :param
          def after_create
            self.param = true
          end
        end
        instance = model.create
        instance.param.should be_true
      end

      should "not insert instance & return nil if before_create throws :halt" do
        model = Class.new(MockContent) do
          attr_accessor :param
          def before_create
            throw :halt
          end
        end
        instance = model.create
        instance.should be_nil
        @database.sqls.should == []
      end

      should "call before save triggers on model create" do
        model = Class.new(MockContent) do
          attr_accessor :param
          def before_save
            self.param = true
          end
        end
        instance = model.create
        instance.param.should be_true
      end

      should "call before save triggers on existing instances" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        model = Class.new(MockContent) do
          attr_accessor :param
          def before_save
            self.param = true
          end
        end
        instance = model.create
        instance.param.should be_true
        instance.set label: "hello"
        instance.param = false
        instance.save
        instance.param.should be_true
      end

      should "call after save triggers after create" do
        model = Class.new(MockContent) do
          attr_accessor :param
          def after_save
            self.param = true
          end
        end
        instance = model.create
        instance.param.should be_true
      end

      should "call after save triggers on existing instances" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        model = Class.new(MockContent) do
          attr_accessor :param
          def after_save
            self.param = true
          end
        end
        instance = model.create
        instance.param.should be_true
        instance.set label: "hello"
        instance.param = false
        instance.save
        instance.param.should be_true
      end

      should "support before_update triggers" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        model = Class.new(MockContent) do
          attr_accessor :param
          def before_update
            self.param = true
          end
        end
        instance = model.create
        instance.param.should be_nil
        instance.set label: "hello"
        instance.save
        instance.param.should be_true
      end

      should "fail to save instance if before_update throws halt" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        model = Class.new(MockContent) do
          attr_accessor :param
          def before_update
            throw :halt
          end
        end
        instance = model.create
        @database.sqls
        instance.set label: "hello"
        result = instance.save
        result.should be_nil
        @database.sqls.should == []
      end

      should "support after update triggers" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        model = Class.new(MockContent) do
          attr_accessor :param
          def after_update
            self.param = true
          end
        end
        instance = model.create
        instance.param.should be_nil
        instance.set label: "hello"
        instance.save
        instance.param.should be_true
      end

      should "support before destroy triggers" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        model = Class.new(MockContent) do
          attr_accessor :param
          def before_destroy
            self.param = true
          end
        end
        instance = model.create
        @database.sqls
        instance.destroy
        instance.param.should be_true
        @database.sqls.should == [
          "DELETE FROM content WHERE (id = 1)"
        ]
      end

      should "not delete an instance if before_destroy throws halt" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        model = Class.new(MockContent) do
          attr_accessor :param
          def before_destroy
            throw :halt
          end
        end
        instance = model.create
        @database.sqls
        result = instance.destroy
        @database.sqls.should == []
        result.should be_nil
      end

      should "support after destroy triggers" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        model = Class.new(MockContent) do
          attr_accessor :param
          def after_destroy
            self.param = true
          end
        end
        instance = model.create
        instance.param.should be_nil
        instance.destroy
        instance.param.should be_true
      end

      should "not trigger before destroy hooks when calling #delete" do
        @database.fetch = { id:1, label:"label", type_sid:"DataMapperTest::MockContent" }
        model = Class.new(MockContent) do
          attr_accessor :param
          def before_destroy
            throw :halt
          end
        end
        instance = model.create
        @database.sqls
        instance.delete
        @database.sqls.should == ["DELETE FROM content WHERE (id = 1)"]
      end

      should "serialize column to JSON" do
        row = { id: 1, type_sid:"DataMapperTest::MockContent" }
        object = {name:"value"}
        serialized = Spontaneous::JSON.encode(object)
        MockContent.serialized_columns.each do |column|
          @database.fetch = row
          instance = MockContent.create({column => object})
          @database.sqls.first.should == "INSERT INTO content (#{column}, type_sid) VALUES ('#{serialized}', 'DataMapperTest::MockContent')"
        end
      end

      should "deserialize objects stored in the db" do
        row = { id: 1, type_sid:"DataMapperTest::MockContent" }
        object = {name:"value"}
        serialized = Spontaneous::JSON.encode(object)
        MockContent.serialized_columns.each do |column|
          @database.fetch = row.merge(column => serialized)
          instance = MockContent.first
          instance.send(column).should == object
        end
      end
      should "save updates to serialized columns" do
        row = { id: 1, type_sid:"DataMapperTest::MockContent" }
        object = {name:"value"}
        serialized = Spontaneous::JSON.encode(object)
        MockContent.serialized_columns.each do |column|
          @database.fetch = row.merge(column => serialized)
          instance = MockContent.first
          @database.sqls
          instance.send(column).should == object
          changed = {name:"it's different", value:[99, 100]}
          instance.send "#{column}=", changed
          instance.send(column).should == changed
          instance.save
          @database.sqls.first.should == "UPDATE content " +
            "SET #{column} = '{\"name\":\"it''s different\",\"value\":[99,100]}' " +
            "WHERE (id = 1)"
        end
      end

      context "timestamps" do
        setup do
          @time = @table.dataset.send :format_timestamp, @now
          @database.columns = @expected_columns + [:created_at, :modified_at]
          TimestampedContent = Spontaneous::DataMapper::Model(:content, @database, @schema)
          @database.sqls
        end

        teardown do
          DataMapperTest.send :remove_const, :TimestampedContent rescue nil
        end

        should "set created_at timestamp on creation" do
          instance = TimestampedContent.create label: "something"
          @database.sqls.first.should == "INSERT INTO content (label, created_at, type_sid) VALUES ('something', #{@time}, 'DataMapperTest::TimestampedContent')"
        end

        # should "update the modified_at value on update" do
        #   @database.fetch = { id: 1, type_sid:"DataMapperTest::TimestampedContent" }
        #   instance = TimestampedContent.create label: "something"
        #   @database.sqls
        #   instance.set label: "changed"
        #   instance.save
        #   @database.sqls.first.should == "UPDATE content SET label = 'changed', modified_at = #{@time} WHERE (id = 1)"
        # end
      end

      context "schema" do
        setup do
          class A1 < MockContent; end
          class A2 < MockContent; end
          class B1 < A1; end
          class B2 < A2; end
          class C1 < B1; end
        end

        teardown do
          %w(A1 A2 B1 B2 C1).each do |klass|
            DataMapperTest.send :remove_const, klass rescue nil
          end
        end

        should "track subclasses" do
          MockContent2.subclasses.should == []
          Set.new(A1.subclasses).should == Set.new([B1, C1])
          A2.subclasses.should == [B2]
          C1.subclasses.should == []
          Set.new(MockContent.subclasses).should == Set.new([MockContent2, A1, A2, B1, B2, C1])
        end
      end
    end

    should "allow for the creation of instance after save hooks" do
      @database.fetch = { id: 1, type_sid:"DataMapperTest::MockContent" }
      instance = MockContent.create label: "something"
      test = false
      instance.after_save_hook do
        test = true
      end
      instance.save
      test.should == true
    end

    should "let you count available instances" do
      result = MockContent.count
      @database.sqls.should == [
        "SELECT COUNT(*) AS count FROM content WHERE (type_sid IN ('DataMapperTest::MockContent')) LIMIT 1"
      ]
    end

    context "has_many associations" do
      setup do
        @database.columns = @expected_columns + [:parent_id, :source_id]
        AssocContent = Spontaneous::DataMapper::Model(:content, @database, @schema)
        AssocContent.has_many :children, key: :parent_id, model: AssocContent
        @database.fetch = { id: 7, type_sid:"DataMapperTest::AssocContent" }
        @parent = AssocContent.first
        @database.sqls
      end

      teardown do
        DataMapperTest.send :remove_const, :AssocContent rescue nil
      end

      should "use the correct dataset" do
        @database.fetch = { id: 7, type_sid:"DataMapperTest::AssocContent" }
        parent = AssocContent.first
        @database.sqls
        @database.fetch = [
          { id: 8, type_sid:"DataMapperTest::MockContent" },
          { id: 9, type_sid:"DataMapperTest::AssocContent" }
        ]
        children = parent.children
        @database.sqls.should == [
          "SELECT * FROM content WHERE (content.parent_id = 7)"
        ]
        children.map(&:id).should == [8, 9]
        children.map(&:class).should == [MockContent, AssocContent]
      end

      should "cache the result" do
        children = @parent.children
        @database.sqls.should == [
          "SELECT * FROM content WHERE (content.parent_id = 7)"
        ]
        children = @parent.children
        @database.sqls.should == [ ]
      end

      should "reload the result if forced" do
        children = @parent.children
        @database.sqls.should == [
          "SELECT * FROM content WHERE (content.parent_id = 7)"
        ]
        children = @parent.children(reload: true)
        @database.sqls.should == [
          "SELECT * FROM content WHERE (content.parent_id = 7)"
        ]
      end

      should "allow access to the relation dataset" do
        ds = @parent.children_dataset
        ds.filter { id > 3}.all
        @database.sqls.should == [
          "SELECT * FROM content WHERE ((content.parent_id = 7) AND (id > 3))"
        ]
      end

      should "return correctly typed results" do
        @database.fetch = [
          { id: 8, type_sid:"DataMapperTest::MockContent" },
          { id: 9, type_sid:"DataMapperTest::AssocContent" }
        ]
        children = @parent.children
        children.map(&:id).should == [8, 9]
        children.map(&:class).should == [MockContent, AssocContent]
      end

      should "correctly set the relation key when adding members" do
        instance = AssocContent.new
        @database.sqls
        @parent.add_child(instance)
        @database.sqls.first.should == \
          "INSERT INTO content (parent_id, type_sid) VALUES (7, 'DataMapperTest::AssocContent')"
      end

      should "use versioned dataset" do
        parent = nil
        @mapper.revision(99) do
          @database.fetch = { id: 7, type_sid:"DataMapperTest::AssocContent" }
          parent = AssocContent.first
          @database.sqls
          children = parent.children
        end
        @database.sqls.should == [
          "SELECT * FROM __r00099_content WHERE (__r00099_content.parent_id = 7)"
        ]
      end

      should "use global dataset version" do
        parent = nil
        @mapper.revision(99) do
          @database.fetch = { id: 7, type_sid:"DataMapperTest::AssocContent" }
          parent = AssocContent.first
          @database.sqls
          @mapper.revision(11) do
            children = parent.children
          end
        end
        @database.sqls.should == [
          "SELECT * FROM __r00011_content WHERE (__r00011_content.parent_id = 7)"
        ]
      end

      should "destroy dependents if configured" do
        AssocContent.has_many :destinations, key: :source_id, model: AssocContent, dependent: :destroy
        @database.fetch = [
          [{ id: 8, type_sid:"DataMapperTest::AssocContent", source_id:7 }],
          [{ id: 9, type_sid:"DataMapperTest::AssocContent", source_id:7 }]
        ]
        @parent.destroy
        @database.sqls.should == [
          "SELECT * FROM content WHERE (content.source_id = 7)",
          "SELECT * FROM content WHERE (content.source_id = 8)",
          "SELECT * FROM content WHERE (content.source_id = 9)",
          "DELETE FROM content WHERE (id = 9)",
          "DELETE FROM content WHERE (id = 8)",
          "DELETE FROM content WHERE (id = 7)"
        ]
      end

      should "delete dependents if configured" do
        AssocContent.has_many :destinations, key: :source_id, model: AssocContent, dependent: :delete
        @database.fetch = [
          [{ id: 8, type_sid:"DataMapperTest::AssocContent", source_id:7 }],
          [{ id: 9, type_sid:"DataMapperTest::AssocContent", source_id:7 }]
        ]
        @parent.destroy
        @database.sqls.should == [
          "DELETE FROM content WHERE (content.source_id = 7)",
          "DELETE FROM content WHERE (id = 7)"
        ]
      end

      should "work with non-mapped models" do
        model = Class.new(Sequel::Model(:other)) do ; end
        model.db = @database
        AssocContent.has_many :others, model: model, key: :user_id
        @database.fetch = { id: 7, type_sid:"DataMapperTest::AssocContent", parent_id: nil }
        instance = AssocContent.first
        @database.sqls
        instance.others
        @database.sqls.should == [
          "SELECT * FROM other WHERE (user_id = 7)"
        ]
      end
    end

    context "belongs_to associations" do
      setup do
        @database.columns = @expected_columns + [:parent_id]
        AssocContent = Spontaneous::DataMapper::Model(:content, @database, @schema)
        AssocContent.has_many   :children, key: :parent_id, model: AssocContent, reciprocal: :parent
        AssocContent.belongs_to :parent,   key: :parent_id, model: AssocContent, reciprocal: :children
        @database.fetch = { id: 8, type_sid:"DataMapperTest::AssocContent", parent_id: 7 }

        @child = AssocContent.first
        @database.sqls
      end

      teardown do
        DataMapperTest.send :remove_const, :AssocContent rescue nil
      end

      should "load the owner" do
        @database.fetch = { id: 7, type_sid:"DataMapperTest::AssocContent", parent_id: nil }
        parent = @child.parent
        @database.sqls.should == ["SELECT * FROM content WHERE (id = 7) LIMIT 1"]
        parent.must_be_instance_of AssocContent
        parent.id.should == 7
      end

      should "cache the result" do
        parent = @child.parent
        @database.sqls.should == ["SELECT * FROM content WHERE (id = 7) LIMIT 1"]
        parent = @child.parent
        @database.sqls.should == [ ]
      end

      should "reload the result if asked" do
        parent = @child.parent
        @database.sqls.should == ["SELECT * FROM content WHERE (id = 7) LIMIT 1"]
        parent = @child.parent(reload: true)
        @database.sqls.should == ["SELECT * FROM content WHERE (id = 7) LIMIT 1"]
      end

      should "allow access to the relation dataset" do
        results = @child.parent_dataset.filter { id > 3 }.first
        @database.sqls.should == ["SELECT * FROM content WHERE ((content.id = 7) AND (id > 3)) LIMIT 1"]
      end

      should "allow setting of owner for instance" do
        instance = AssocContent.new
        @database.sqls
        instance.parent = @child
        instance.parent_id.should == 8
        instance.save
        @database.sqls.first.should == \
          "INSERT INTO content (parent_id, type_sid) VALUES (8, 'DataMapperTest::AssocContent')"
      end

      should "set the reciprocal relation" do
        @database.fetch = { id: 7, type_sid:"DataMapperTest::AssocContent" }
        parent = AssocContent.first
        @database.sqls
        @database.fetch = [
          { id: 8, type_sid:"DataMapperTest::AssocContent", parent_id: 7 },
          { id: 9, type_sid:"DataMapperTest::AssocContent", parent_id: 7 }
        ]
        children = parent.children
        children.map { |c| c.parent.object_id }.uniq.should == [parent.object_id]
        @database.sqls.should == [
          "SELECT * FROM content WHERE (content.parent_id = 7)"
        ]
      end
    end

    context "performance" do
      should "use a cached version within revision blocks" do
        @mapper.revision(20) do
          assert @mapper.dataset.equal?(@mapper.dataset), "Dataset should be the same object"
        end
      end

      should "use an identity map within revision scopes" do
        @database.fetch = [
          { id: 7, type_sid:"DataMapperTest::MockContent", parent_id: 7 }
        ]
        @mapper.editable do
          a = @mapper.first! :id => 7
          b = @mapper.first! :id => 7
          assert a.object_id == b.object_id, "a and b should be the same object"
        end
      end

      should "use an object cache for #get calls" do
        @database.fetch = [
          [{ id: 8, type_sid:"DataMapperTest::MockContent", parent_id: 7 }],
          [{ id: 9, type_sid:"DataMapperTest::MockContent", parent_id: 7 }]
        ]
        @mapper.revision(20) do
          a = @mapper.get(8)
          b = @mapper.get(9)
          @database.sqls
          a = @mapper.get(8)
          b = @mapper.get(9)
          @database.sqls.should == []
        end
      end

      should "not create new scope if revisions are the same" do
        a = b = nil
        @mapper.revision(20) do
          a = @mapper.dataset
          @mapper.revision(20) do
            b = @mapper.dataset
          end
        end
        assert a.object_id == b.object_id, "Mappers should be same object"
      end

      should "not create new scope if visibility are the same" do
        a = b = nil
        @mapper.scope(20, true) do
          a = @mapper.dataset
          @mapper.visible do
            b = @mapper.dataset
          end
        end
        assert a.object_id == b.object_id, "Mappers should be same object"
      end

      should "not create new scope if parameters are the same" do
        a = b = nil
        @mapper.scope(20, true) do
          a = @mapper.dataset
          @mapper.scope(20, true) do
            b = @mapper.dataset
          end
        end
        assert a.object_id == b.object_id, "Mappers should be same object"
      end

      should "allow for using a custom cache key" do
        @database.fetch = [
          { id: 20, type_sid:"DataMapperTest::MockContent", parent_id: 7 }
        ]
        a = b = nil
        @mapper.scope(20, false) do
          a = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
          b = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
        end
        @database.sqls.should == [
          "SELECT * FROM __r00020_content WHERE (label = 'frog') LIMIT 1"
        ]
      end
    end
  end
end

# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'sequel'

describe "DataMapper" do

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

  before do
    @site = setup_site
    @now = Spontaneous::DataMapper.timestamp
    @expected_columns = [:id, :type_sid, :label, :object1, :object2]
    @database = ::Sequel.mock(autoid: 1)
    @table = Spontaneous::DataMapper::ContentTable.new(:content, @database)
    @schema = Spontaneous::Schema.new(@site, Dir.pwd, NameMap)
    @mapper = Spontaneous::DataMapper.new(@table, @schema)
    @database.columns = @expected_columns
    Spontaneous::DataMapper.stubs(:timestamp).returns(@now)
    MockContent = Spontaneous::DataMapper::Model(:content, @database, @schema) do
      serialize_columns :object1, :object2
    end
    # having timestamps on makes testing the sql very difficult/tedious
    MockContent2 = Class.new(MockContent)
    MockContent3 = Class.new(MockContent)
    @database.sqls # clear sql log -- column introspection makes a query to the db
  end

  after do
    Object.send :remove_const, :MockContent rescue nil
    Object.send :remove_const, :MockContent2 rescue nil
    Object.send :remove_const, :MockContent3 rescue nil
    teardown_site
  end

  it "be creatable from any table" do
    table = Spontaneous::DataMapper::ContentTable.new(:content, @database)
    mapper = Spontaneous::DataMapper.new(table, @schema)
    mapper.must_be_instance_of Spontaneous::DataMapper::ScopingMapper
  end

  describe "instances" do
    it "insert model data when saving a new model instance" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      instance = MockContent2.new(:label => "column1")
      assert instance.new?
      @mapper.create(instance)
      @database.sqls.must_equal [
        "INSERT INTO content (label, type_sid) VALUES ('column1', 'MockContent2')",
        "SELECT * FROM content WHERE (id = 1) LIMIT 1"
      ]
      refute instance.new?
      instance.id.must_equal 1
    end

    it "insert models using the DataMapper.create method" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      instance = @mapper.instance MockContent2, :label => "column1"
      @database.sqls.must_equal [
        "INSERT INTO content (label, type_sid) VALUES ('column1', 'MockContent2')",
        "SELECT * FROM content WHERE (id = 1) LIMIT 1"
      ]
      refute instance.new?
      instance.id.must_equal 1
    end

    it "update an existing model" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      instance = @mapper.instance MockContent2, :label => "column1"
      instance.set label: "changed"
      @mapper.save(instance)
      @database.sqls.must_equal [
        "INSERT INTO content (label, type_sid) VALUES ('column1', 'MockContent2')",
        "SELECT * FROM content WHERE (id = 1) LIMIT 1",
        "UPDATE content SET label = 'changed' WHERE (id = 1)"
      ]
    end

    it "update model rows directly" do
      @mapper.update([MockContent2], label: "changed")
      @database.sqls.must_equal [
        "UPDATE content SET label = 'changed' WHERE (type_sid IN ('MockContent2'))"
      ]
    end

    it "find an existing model" do
      instance = @mapper.instance MockContent2, :label => "column1"
      @database.sqls # clear the sql log
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      instance = @mapper.get(1)
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1"
      ]
      instance.must_be_instance_of MockContent2
      instance.id.must_equal 1
      instance.attributes[:label].must_equal "column1"
    end

    it "responds to Sequel's #primary_key_lookup" do
      @database.sqls # clear the sql log
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      instance = @mapper.primary_key_lookup(1)
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1"
      ]
    end

    it "retirieve a list of objects in the specified order" do
      # instance = @mapper.instance MockContent2, :label => "column1"
      @database.sqls # clear the sql log
      @database.fetch = [
        { id:1, type_sid:"MockContent2" },
        { id:2, type_sid:"MockContent2" },
        { id:3, type_sid:"MockContent2" },
        { id:4, type_sid:"MockContent2" }
      ]
      results = @mapper.get([2, 3, 4, 1])
      results.map(&:id).must_equal [2, 3, 4, 1]
    end

    it "allow for finding the first instance of a model" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      instance = @mapper.first([MockContent2], id: 1)
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2')) AND (id = 1)) LIMIT 1"
      ]
    end

    it "be scopable to a revision" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      @mapper.revision(10) do
        instance = @mapper.instance MockContent2, :label => "column1"
        instance.set label: "changed"
        @mapper.save(instance)
        @database.sqls.must_equal [
          "INSERT INTO __r00010_content (label, type_sid) VALUES ('column1', 'MockContent2')",
          "SELECT * FROM __r00010_content WHERE (id = 1) LIMIT 1",
          "UPDATE __r00010_content SET label = 'changed' WHERE (id = 1)"
        ]
      end
    end

    it "return the correct table name" do
      @mapper.table_name.must_equal :"content"
      @mapper.revision(10) do
        @mapper.table_name.must_equal :"__r00010_content"
      end
    end

    it "knows if the scope is editable" do
      @mapper.revision(10) do
        @mapper.editable?.must_equal false
      end
      @mapper.editable do
        @mapper.editable?.must_equal true
      end
    end

    it "allow for retrieval of rows from a specific revision" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      instance = @mapper.revision(20).get(1)
      @database.sqls.must_equal ["SELECT * FROM __r00020_content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1"]
      instance.must_be_instance_of MockContent2
      instance.id.must_equal 1
      instance.attributes[:label].must_equal "column1"
    end

    it "support nested revision scopes" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
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
      @database.sqls.must_equal [
        "SELECT * FROM __r00010_content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1",
        "UPDATE __r00010_content SET label = 'changed1' WHERE (id = 1)",
        "SELECT * FROM __r00020_content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1",
        "UPDATE __r00020_content SET label = 'changed2' WHERE (id = 1)",
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id = 3)) LIMIT 1"
      ]
    end

    it "allow for finding all instances of a class with DataMapper#all" do
      @database.fetch = [
        { id:1, label:"column1", type_sid:"MockContent2" },
        { id:2, label:"column2", type_sid:"MockContent3" }
      ]
      results = @mapper.all([MockContent2, MockContent3])
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE (type_sid IN ('MockContent2', 'MockContent3'))"
      ]
      results.map(&:class).must_equal [MockContent2, MockContent3]
      results.map(&:id).must_equal [1, 2]
    end

    it "allow for counting type rows" do
      @mapper.count([MockContent2, MockContent3])
      @database.sqls.must_equal [
        "SELECT count(*) AS count FROM content WHERE (type_sid IN ('MockContent2', 'MockContent3')) LIMIT 1"
      ]
    end

    it "allow for use of block iterator when loading all model instances" do
      ids = []
      @database.fetch = [
        { id:1, label:"column1", type_sid:"MockContent2" },
        { id:2, label:"column2", type_sid:"MockContent3" }
      ]
      results = @mapper.all([MockContent2, MockContent3]) do |i|
        ids << i.id
      end
      ids.must_equal [1, 2]
      results.map(&:class).must_equal [MockContent2, MockContent3]
    end

    it "allow for defining an order" do
      ds = @mapper.order([MockContent2], "column1").all
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE (type_sid IN ('MockContent2')) ORDER BY 'column1'"
      ]
    end

    it "allow for defining a limit" do
      ds = @mapper.limit([MockContent2], 10...20).all
      ds = @mapper.filter([], label: "this").limit(10).all
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE (type_sid IN ('MockContent2')) LIMIT 10 OFFSET 10",
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (label = 'this')) LIMIT 10"
      ]
    end

    it "support chained filters" do
      @database.fetch = [
        { id:1, label:"column1", type_sid:"MockContent2" }
      ]
      ds = @mapper.filter([MockContent2, MockContent3], id:1)
      results = ds.all
      results.map(&:class).must_equal [MockContent2]
      results.map(&:id).must_equal [1]
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1))"
      ]
    end

    it "supports the exclude method" do
      @mapper.exclude([MockContent2], label: "this").all
      @mapper.exclude!(label: "this").all
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2')) AND (label != 'this'))",
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (label != 'this'))"
      ]
    end

    it "support filtering using virtual rows" do
      @database.fetch = [
        { id:1, label:"column1", type_sid:"MockContent2" },
        { id:2, label:"column2", type_sid:"MockContent3" }
      ]
      ds = @mapper.filter([MockContent2, MockContent3]) { id > 0 }
      results = ds.all
      results.map(&:class).must_equal [MockContent2, MockContent3]
      results.map(&:id).must_equal [1, 2]
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id > 0))"
      ]
    end

    it "support multiple concurrent filters" do
      # want to be sure that each dataset is independent
      ds1 = @mapper.filter([MockContent2], id: 1)
      ds2 = @mapper.filter([MockContent3])

      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      ds1.first([]).must_be_instance_of MockContent2

      @database.fetch = { id:2, label:"column2", type_sid:"MockContent3" }
      ds2.first([]).must_be_instance_of MockContent3

      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2')) AND (id = 1)) LIMIT 1",
        "SELECT * FROM content WHERE (type_sid IN ('MockContent3')) LIMIT 1"
      ]
    end


    it "allows you to invert the conditions" do
      ds = @mapper.filter([MockContent2]).invert.all
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE (type_sid NOT IN ('MockContent2'))",
      ]
    end

    it "allow you to delete all content" do
      @mapper.delete
      @database.sqls.must_equal [
        "DELETE FROM content"
      ]
    end

    it "allow you to delete datasets" do
      @mapper.delete([MockContent2])
      @database.sqls.must_equal [
        "DELETE FROM content WHERE (type_sid IN ('MockContent2'))"
      ]
    end

    it "allow you to delete instances" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      instance = @mapper.instance MockContent2, label: "label"
      @database.sqls
      @mapper.delete_instance instance
      @database.sqls.must_equal [
        "DELETE FROM content WHERE (id = 1)"
      ]
    end

    it "allow you to delete instances within a revision" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      instance = @mapper.instance MockContent2, label: "label"
      @database.sqls
      @mapper.revision(20) do
        @mapper.delete_instance instance
      end
      @database.sqls.must_equal [
        "DELETE FROM __r00020_content WHERE (id = 1)"
      ]
    end

    it "allow you to destroy model instances" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      instance = @mapper.instance MockContent2, :label => "column1"
      @database.sqls # clear sql log
      @mapper.delete_instance instance
      instance.id.must_equal 1
      @database.sqls.must_equal [
        "DELETE FROM content WHERE (id = 1)"
      ]
    end

    it "support visibility contexts" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      @mapper.visible do
        @mapper.get(1)
        @mapper.visible(false) do
          @mapper.get(1)
          @mapper.visible.get(1)
        end
      end
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((hidden IS FALSE) AND (type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1",
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1",
        "SELECT * FROM content WHERE ((hidden IS FALSE) AND (type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1",
      ]
    end

    it "support mixed revision & visibility states" do
      @database.fetch = { id:1, label:"column1", type_sid:"MockContent2" }
      @mapper.revision(25) do
        @mapper.visible do
          @mapper.get(1)
        end
      end
      @database.sqls.must_equal [
        "SELECT * FROM __r00025_content WHERE ((hidden IS FALSE) AND (type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1",
      ]
    end

    it "ignore visibility filter for deletes" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      instance = @mapper.instance MockContent2, label: "label"
      @database.sqls
      @mapper.visible do
        @mapper.delete_instance(instance)
      end
      @database.sqls.must_equal [
        "DELETE FROM content WHERE (id = 1)",
      ]
    end

    it "ignore visibility setting for creates" do
      @mapper.visible do
        @mapper.revision(99) do
          instance = @mapper.instance MockContent2, :label => "column1"
        end
      end
      @database.sqls.must_equal [
        "INSERT INTO __r00099_content (label, type_sid) VALUES ('column1', 'MockContent2')",
        "SELECT * FROM __r00099_content WHERE (id = 1) LIMIT 1"
      ]
    end

    it "allow for inserting raw attributes" do
      @mapper.insert type_sid: "MockContent2", label: "label"
      @database.sqls.must_equal [
        "INSERT INTO content (type_sid, label) VALUES ('MockContent2', 'label')"
      ]
    end
  end

  describe "prepared statements" do
    it "allows for defining the same prepared statements in multiple scopes" do
      sqls = []
      ps0 = @mapper.prepare(:select, :something) { @mapper.filter(MockContent2, label: :$label) }
      @mapper.visible do
        ps1 = @mapper.prepare(:select, :something) { @mapper.filter(MockContent2, label: :$label) }
        ps2 = @mapper.prepare(:select, :something) { @mapper.filter(MockContent2, label: :$label) }
        ps1.object_id.must_equal ps2.object_id
        ps0.object_id.wont_equal ps1.object_id
        @mapper.scope(23, true) do
          ps3 = @mapper.prepare(:select, :something) { @mapper.filter(MockContent2, label: :$label) }
          ps1.object_id.wont_equal ps3.object_id
          ps0.object_id.wont_equal ps3.object_id
        end
      end
      @database.prepared_statements.values.map(&:sql).must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2')) AND (label = $label))",
        "SELECT * FROM content WHERE ((hidden IS FALSE) AND (type_sid IN ('MockContent2')) AND (label = $label))",
        "SELECT * FROM __r00023_content WHERE ((hidden IS FALSE) AND (type_sid IN ('MockContent2')) AND (label = $label))"
      ]
    end
  end

  describe "models" do
    it "can clean the db completely" do
      def MockContent.types
        nil
      end
      MockContent.delete
      @database.sqls.must_equal [
        "DELETE FROM content"
      ]
    end

    it "be deletable" do
      MockContent2.delete
      @database.sqls.must_equal [
        "DELETE FROM content WHERE (type_sid IN ('MockContent2'))"
      ]
    end

    it "be creatable using Model.create" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(label: "value")
      @database.sqls.must_equal [
        "INSERT INTO content (label, type_sid) VALUES ('value', 'MockContent2')",
        "SELECT * FROM content WHERE (id = 1) LIMIT 1"
      ]
      refute instance.new?
      instance.id.must_equal 1
    end

    it "be instantiable using Model.new" do
      instance = MockContent2.new(label: "value")
      assert instance.new?
    end

    it "be creatable using Model.new" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.new(label: "value")
      instance.save
      refute instance.new?
      @database.sqls.must_equal [
        "INSERT INTO content (label, type_sid) VALUES ('value', 'MockContent2')",
        "SELECT * FROM content WHERE (id = 1) LIMIT 1"
      ]
      instance.id.must_equal 1
    end

    it "be updatable" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(label: "value")
      instance.update(label: "changed")
      @database.sqls.must_equal [
        "INSERT INTO content (label, type_sid) VALUES ('value', 'MockContent2')",
        "SELECT * FROM content WHERE (id = 1) LIMIT 1",
        "UPDATE content SET label = 'changed' WHERE (id = 1)"
      ]
    end

    it "exclude id column from updates" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(id: 103, label: "value")
      instance.id.must_equal 1
      instance.update(id: 99, label: "changed")
      @database.sqls.must_equal [
        "INSERT INTO content (label, type_sid) VALUES ('value', 'MockContent2')",
        "SELECT * FROM content WHERE (id = 1) LIMIT 1",
        "UPDATE content SET label = 'changed' WHERE (id = 1)"
      ]
      instance.id.must_equal 1
    end

    it "exclude type_sid column from updates" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(type_sid: "Nothing", label: "value")
      instance.update(type_sid: "Invalid", label: "changed")
      @database.sqls.must_equal [
        "INSERT INTO content (label, type_sid) VALUES ('value', 'MockContent2')",
        "SELECT * FROM content WHERE (id = 1) LIMIT 1",
        "UPDATE content SET label = 'changed' WHERE (id = 1)"
      ]
      instance.id.must_equal 1
    end

    it "only update changed columns" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(label: "value")
      @database.sqls
      instance.changed_columns.must_equal []
      instance.label = "changed"
      instance.changed_columns.must_equal [:label]
      instance.object1 = "updated"
      instance.changed_columns.must_equal [:label, :object1]
      instance.save
      @database.sqls.must_equal [
        "UPDATE content SET label = 'changed', object1 = '\"updated\"' WHERE (id = 1)"
      ]
    end

    it "mark new instances as modified" do
      instance = MockContent2.new(label: "value")
      assert instance.modified?
    end

    it "updated modified flag after save" do
      instance = MockContent2.new(label: "value")
      instance.save
      refute instance.modified?
    end

    it "have a modified flag if columns changed" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(label: "value")
      refute instance.modified?
      instance.label = "changed"
      assert instance.modified?
    end

    it "not make a db call if no values have been modified" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(label: "value")
      @database.sqls
      instance.save
      @database.sqls.must_equal []
    end

    it "allow you to force a save" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(label: "value")
      @database.sqls
      instance.mark_modified!
      instance.save
      @database.sqls.must_equal [
        "UPDATE content SET label = 'value', type_sid = 'MockContent2' WHERE (id = 1)"
      ]
    end

    it "allow you to force an update to a specific column" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(label: "value")
      @database.sqls
      instance.mark_modified!(:label)
      instance.save
      @database.sqls.must_equal [
        "UPDATE content SET label = 'value' WHERE (id = 1)"
      ]
    end

    it "be destroyable" do
      @database.fetch = { id:1, label:"value", type_sid:"MockContent2" }
      instance = MockContent2.create(label: "value")
      instance.id.must_equal 1
      instance.destroy
      @database.sqls.must_equal [
        "INSERT INTO content (label, type_sid) VALUES ('value', 'MockContent2')",
        "SELECT * FROM content WHERE (id = 1) LIMIT 1",
        "DELETE FROM content WHERE (id = 1)"
      ]
    end

    it "allow for searching for all instances of a class" do
      @database.fetch = [
        { id:1, label:"column1", type_sid:"MockContent2" },
        { id:2, label:"column2", type_sid:"MockContent2" }
      ]
      results = MockContent2.all
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE (type_sid IN ('MockContent2'))"
      ]
      results.length.must_equal 2
      results.map(&:class).must_equal [MockContent2, MockContent2]
      results.map(&:id).must_equal [1, 2]
    end

    it "allow for finding first instance of a type" do
      @database.fetch = [
        { id:1, label:"column1", type_sid:"MockContent2" }
      ]
      instance = MockContent2.first
      MockContent2.first(id: 1)
      MockContent2.first { id > 0}
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE (type_sid IN ('MockContent2')) LIMIT 1",
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2')) AND (id = 1)) LIMIT 1",
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2')) AND (id > 0)) LIMIT 1"
      ]
      instance.must_be_instance_of MockContent2
      instance.id.must_equal 1
    end

    it "return nil if no instance matching filter is found" do
      @database.fetch = []
      instance = MockContent2.first(id: 1)
      instance.must_be_nil
    end

    it "retrieve by primary key using []" do
      instance = MockContent2[1]
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (id = 1)) LIMIT 1",
      ]
    end

    it "have correct equality test" do
      @database.fetch = [
        { id:1, label:"column1", type_sid:"MockContent2" }
      ]
      a = MockContent2[1]
      b = MockContent2[1]
      a.must_equal b

      a.label = "changed"
      a.wont_equal b
    end

    it "allow for filtering model instances" do
      @database.fetch = [
        { id:100, label:"column1", type_sid:"MockContent2" }
      ]
      results = MockContent2.filter(hidden: false).all
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2')) AND (hidden IS FALSE))"
      ]
      results.length.must_equal 1
      results.map(&:class).must_equal [MockContent2]
      results.map(&:id).must_equal [100]
    end

    it "use the current mapper revision to save" do
      @database.fetch = [
        { id:100, label:"column1", type_sid:"MockContent2" }
      ]
      instance = nil
      @mapper.revision(99) do
        instance = MockContent2.first
      end
      instance.update(label: "changed")
      @mapper.revision(99) do
        instance.update(label: "changed2")
      end
      @database.sqls.must_equal [
        "SELECT * FROM __r00099_content WHERE (type_sid IN ('MockContent2')) LIMIT 1",
        "UPDATE content SET label = 'changed' WHERE (id = 100)",
        "UPDATE __r00099_content SET label = 'changed2' WHERE (id = 100)"
      ]
    end

    it "allow for reloading values from the db" do
      @database.fetch = { id:100, label:"column1", type_sid:"MockContent2" }
      instance = MockContent2.first
      instance.set(label:"changed")
      instance.attributes[:label].must_equal "changed"
      instance.changed_columns.must_equal [:label]
      instance.reload
      instance.attributes[:label].must_equal "column1"
      instance.changed_columns.must_equal []
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE (type_sid IN ('MockContent2')) LIMIT 1",
        "SELECT * FROM content WHERE (id = 100) LIMIT 1"
      ]
    end


    it "update model rows directly" do
      MockContent2.update(label: "changed")
      @database.sqls.must_equal [
        "UPDATE content SET label = 'changed' WHERE (type_sid IN ('MockContent2'))"
      ]
    end

    it "introspect columns" do
      MockContent2.columns.must_equal @expected_columns
    end

    it "create getters & setters for all columns except id & type_sid" do
      columns = (@expected_columns - [:id, :type_sid])
      attrs = Hash[columns.map { |c| [c, "#{c}_value"] } ]
      c = MockContent2.new attrs

      columns.each do |column|
        assert c.respond_to?(column), "Instance it respond to ##{column}"
        assert c.respond_to?("#{column}="), "Instance it respond to ##{column}="
        c.send(column).must_equal attrs[column]
        c.send("#{column}=", "changed")
        c.send(column).must_equal "changed"
      end
    end

    it "set values using the setter methods" do
      model = Class.new(MockContent) do
        def label=(value); super(value + "!"); end
      end
      instance = model.new label: "label1"
      instance.set(label: "label2")
      instance.label.must_equal "label2!"
    end

    it "support after_initialize hooks" do
      model = Class.new(MockContent2) do
        attr_accessor :param
        def after_initialize
          self.param = true
        end
      end
      instance = model.new
      assert instance.param
    end

    it "support before create triggers" do
      model = Class.new(MockContent2) do
        attr_accessor :param
        def before_create
          self.param = true
        end
      end
      instance = model.create
      assert instance.param
    end

    it "support after create triggers" do
      model = Class.new(MockContent2) do
        attr_accessor :param
        def after_create
          self.param = true
        end
      end
      instance = model.create
      assert instance.param
    end

    it "not insert instance & return nil if before_create throws :halt" do
      model = Class.new(MockContent2) do
        attr_accessor :param
        def before_create
          throw :halt
        end
      end
      instance = model.create
      instance.must_be_nil
      @database.sqls.must_equal []
    end

    it "call before save triggers on model create" do
      model = Class.new(MockContent2) do
        attr_accessor :param
        def before_save
          self.param = true
        end
      end
      instance = model.create
      assert instance.param
    end

    it "call before save triggers on existing instances" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      model = Class.new(MockContent2) do
        attr_accessor :param
        def before_save
          self.param = true
        end
      end
      instance = model.create
      assert instance.param
      instance.set label: "hello"
      instance.param = false
      instance.save
      assert instance.param
    end

    it "call after save triggers after create" do
      model = Class.new(MockContent2) do
        attr_accessor :param
        def after_save
          self.param = true
        end
      end
      instance = model.create
      assert instance.param
    end

    it "call after save triggers on existing instances" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      model = Class.new(MockContent2) do
        attr_accessor :param
        def after_save
          self.param = true
        end
      end
      instance = model.create
      assert instance.param
      instance.set label: "hello"
      instance.param = false
      instance.save
      assert instance.param
    end

    it "support before_update triggers" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      model = Class.new(MockContent2) do
        attr_accessor :param
        def before_update
          self.param = true
        end
      end
      instance = model.create
      instance.param.must_be_nil
      instance.set label: "hello"
      instance.save
      assert instance.param
    end

    it "fail to save instance if before_update throws halt" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      model = Class.new(MockContent2) do
        attr_accessor :param
        def before_update
          throw :halt
        end
      end
      instance = model.create
      @database.sqls
      instance.set label: "hello"
      result = instance.save
      result.must_be_nil
      @database.sqls.must_equal []
    end

    it "support after update triggers" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      model = Class.new(MockContent2) do
        attr_accessor :param
        def after_update
          self.param = true
        end
      end
      instance = model.create
      instance.param.must_be_nil
      instance.set label: "hello"
      instance.save
      assert instance.param
    end

    it "support before destroy triggers" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      model = Class.new(MockContent2) do
        attr_accessor :param
        def before_destroy
          self.param = true
        end
      end
      instance = model.create
      @database.sqls
      instance.destroy
      assert instance.param
      @database.sqls.must_equal [
        "DELETE FROM content WHERE (id = 1)"
      ]
    end

    it "not delete an instance if before_destroy throws halt" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      model = Class.new(MockContent2) do
        attr_accessor :param
        def before_destroy
          throw :halt
        end
      end
      instance = model.create
      @database.sqls
      result = instance.destroy
      @database.sqls.must_equal []
      result.must_be_nil
    end

    it "support after destroy triggers" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      model = Class.new(MockContent2) do
        attr_accessor :param
        def after_destroy
          self.param = true
        end
      end
      instance = model.create
      instance.param.must_be_nil
      instance.destroy
      assert instance.param
    end

    it "not trigger before destroy hooks when calling #delete" do
      @database.fetch = { id:1, label:"label", type_sid:"MockContent2" }
      model = Class.new(MockContent2) do
        attr_accessor :param
        def before_destroy
          throw :halt
        end
      end
      instance = model.create
      @database.sqls
      instance.delete
      @database.sqls.must_equal ["DELETE FROM content WHERE (id = 1)"]
    end

    it "serialize column to JSON" do
      row = { id: 1, type_sid:"MockContent2" }
      object = {name:"value"}
      serialized = Spontaneous::JSON.encode(object)
      MockContent2.serialized_columns.each do |column|
        @database.fetch = row
        instance = MockContent2.create({column => object})
        @database.sqls.first.must_equal "INSERT INTO content (#{column}, type_sid) VALUES ('#{serialized}', 'MockContent2')"
      end
    end

    it "deserialize objects stored in the db" do
      row = { id: 1, type_sid:"MockContent2" }
      object = {name:"value"}
      serialized = Spontaneous::JSON.encode(object)
      MockContent2.serialized_columns.each do |column|
        @database.fetch = row.merge(column => serialized)
        instance = MockContent2.first
        instance.send(column).must_equal object
      end
    end
    it "save updates to serialized columns" do
      row = { id: 1, type_sid:"MockContent2" }
      object = {name:"value"}
      serialized = Spontaneous::JSON.encode(object)
      MockContent2.serialized_columns.each do |column|
        @database.fetch = row.merge(column => serialized)
        instance = MockContent2.first
        @database.sqls
        instance.send(column).must_equal object
        changed = {name:"it's different", value:[99, 100]}
        instance.send "#{column}=", changed
        instance.send(column).must_equal changed
        instance.save
        @database.sqls.first.must_equal "UPDATE content " +
          "SET #{column} = '{\"name\":\"it''s different\",\"value\":[99,100]}' " +
          "WHERE (id = 1)"
      end
    end

    describe "timestamps" do
      before do
        @time = @table.dataset.send :format_timestamp, @now
        @database.columns = @expected_columns + [:created_at, :modified_at]
        ::TimestampedContent = Spontaneous::DataMapper::Model(:content, @database, @schema)
        @database.sqls
      end

      after do
        Object.send :remove_const, :TimestampedContent rescue nil
      end

      it "set created_at timestamp on creation" do
        instance = TimestampedContent.create label: "something"
        @database.sqls.first.must_equal "INSERT INTO content (label, created_at, modified_at, type_sid) VALUES ('something', #{@time}, #{@time}, 'TimestampedContent')"
      end

      it "update the modified_at value on update" do
        @database.fetch = { id: 1, type_sid:"TimestampedContent" }
        instance = TimestampedContent.create label: "something"
        @database.sqls
        instance.set label: "changed"
        instance.save
        @database.sqls.first.must_equal "UPDATE content SET label = 'changed', modified_at = #{@time} WHERE (id = 1)"
      end
    end

    describe "schema" do
      before do
        class A1 < MockContent; end
        class A2 < MockContent; end
        class B1 < A1; end
        class B2 < A2; end
        class C1 < B1; end
      end

      after do
        %w(A1 A2 B1 B2 C1).each do |klass|
          DataMapperTest.send :remove_const, klass rescue nil
        end
      end

      it "track subclasses" do
        MockContent2.subclasses.must_equal []
        Set.new(A1.subclasses).must_equal Set.new([B1, C1])
        A2.subclasses.must_equal [B2]
        C1.subclasses.must_equal []
        Set.new(MockContent.subclasses).must_equal Set.new([MockContent2, MockContent3, A1, A2, B1, B2, C1])
      end
    end
  end

  it "allow for the creation of instance after save hooks" do
    @database.fetch = { id: 1, type_sid:"MockContent2" }
    instance = MockContent2.create label: "something"
    test = false
    instance.after_save_hook do
      test = true
    end
    instance.save
    test.must_equal true
  end

  it "let you count available instances" do
    result = MockContent2.count
    @database.sqls.must_equal [
      "SELECT count(*) AS count FROM content WHERE (type_sid IN ('MockContent2')) LIMIT 1"
    ]
  end

  describe "has_many associations" do
    before do
      @database.columns = @expected_columns + [:parent_id, :source_id]
      AssocContent = Spontaneous::DataMapper::Model(:content, @database, @schema)
      AssocContent.has_many_content :children, key: :parent_id#, model: AssocContent
      @database.fetch = { id: 7, type_sid:"AssocContent" }
      @parent = AssocContent.first
      @database.sqls
      @database.columns = nil
    end

    after do
      Object.send :remove_const, :AssocContent rescue nil
    end

    it "use the correct dataset" do
      @database.fetch = { id: 7, type_sid:"AssocContent" }
      parent = AssocContent.first
      @database.sqls
      @database.fetch = [
        { id: 8, type_sid:"MockContent2" },
        { id: 9, type_sid:"AssocContent" }
      ]
      children = parent.children
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.parent_id = 7))"
      ]
      children.map(&:id).must_equal [8, 9]
      children.map(&:class).must_equal [MockContent2, AssocContent]
    end

    it "cache the result" do
      children = @parent.children
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.parent_id = 7))"
      ]
      children = @parent.children
      @database.sqls.must_equal [ ]
    end

    it "reload the result if forced" do
      children = @parent.children
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.parent_id = 7))"
      ]
      children = @parent.children(reload: true)
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.parent_id = 7))"
      ]
    end

    it "allow access to the relation dataset" do
      ds = @parent.children_dataset
      ds.filter { id > 3}.all
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.parent_id = 7) AND (id > 3))"
      ]
    end

    it "return correctly typed results" do
      @database.fetch = [
        { id: 8, type_sid:"MockContent2" },
        { id: 9, type_sid:"AssocContent" }
      ]
      children = @parent.children
      children.map(&:id).must_equal [8, 9]
      children.map(&:class).must_equal [MockContent2, AssocContent]
    end

    it "correctly set the relation key when adding members" do
      instance = AssocContent.new
      @database.sqls
      @parent.add_child(instance)
      @database.sqls.first.must_equal \
        "INSERT INTO content (parent_id, type_sid) VALUES (7, 'AssocContent')"
    end

    it "use versioned dataset" do
      parent = nil
      @mapper.revision(99) do
        @database.fetch = { id: 7, type_sid:"AssocContent" }
        parent = AssocContent.first
        @database.sqls
        children = parent.children
      end
      @database.sqls.must_equal [
        "SELECT * FROM __r00099_content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (__r00099_content.parent_id = 7))"
      ]
    end

    it "use global dataset version" do
      parent = nil
      @mapper.revision(99) do
        @database.fetch = { id: 7, type_sid:"AssocContent" }
        parent = AssocContent.first
        @database.sqls
        @mapper.revision(11) do
          children = parent.children
        end
      end
      @database.sqls.must_equal [
        "SELECT * FROM __r00011_content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (__r00011_content.parent_id = 7))"
      ]
    end

    it "destroy dependents if configured" do
      AssocContent.has_many_content :destinations, key: :source_id, dependent: :destroy
      @database.fetch = [
        [{ id: 8, type_sid:"AssocContent", source_id:7 }],
        [{ id: 9, type_sid:"AssocContent", source_id:7 }]
      ]
      @parent.destroy
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.source_id = 7))",
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.source_id = 8))",
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.source_id = 9))",
        "DELETE FROM content WHERE (id = 9)",
        "DELETE FROM content WHERE (id = 8)",
        "DELETE FROM content WHERE (id = 7)"
      ]
    end

    it "delete dependents if configured" do
      AssocContent.has_many_content :destinations, key: :source_id, dependent: :delete
      @database.fetch = [
        [{ id: 8, type_sid:"AssocContent", source_id:7 }],
        [{ id: 9, type_sid:"AssocContent", source_id:7 }]
      ]
      @parent.destroy
      @database.sqls.must_equal [
        "DELETE FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.source_id = 7))",
        "DELETE FROM content WHERE (id = 7)"
      ]
    end

    describe "sequel models" do
      before do
        ::Other = Class.new(Sequel::Model(:other)) do ; end
        Other.db = @database
        AssocContent.one_to_many :others, key: :user_id
        @database.fetch = { id: 7, type_sid:"AssocContent", parent_id: nil }
        @instance = AssocContent.first
        @database.sqls
      end

      after do
          Object.send :remove_const, :Other rescue nil
      end

      it "can load association members" do
        @instance.others
        @database.sqls.must_equal [
          "SELECT * FROM other WHERE (other.user_id = 7)"
        ]
      end

      it "can add new association members" do
        other = Other.new
        other.expects(:user_id=).with(7)
        @instance.add_other other
      end

      it "can remove association members" do
        other = Other.new
        other.expects(:user_id=).with(nil)
        @instance.remove_other other
      end

      it "can remove all members" do
        @instance.remove_all_others
        @database.sqls.must_equal [
          "UPDATE other SET user_id = NULL WHERE (user_id = 7)"
        ]
      end

      it "can access the association dataset" do
        @instance.others_dataset.sql.must_equal "SELECT * FROM other WHERE (other.user_id = 7)"
      end
    end
  end

  describe "belongs_to associations" do
    before do
      @columns = @expected_columns + [:parent_id]
      @database.columns = @columns
      AssocContent = Spontaneous::DataMapper::Model(:content, @database, @schema)
      AssocContent.has_many_content   :children, key: :parent_id, reciprocal: :parent
      AssocContent.belongs_to_content :parent,   key: :parent_id, reciprocal: :children
      @database.fetch = { id: 8, type_sid:"AssocContent", parent_id: 7 }

      @child = AssocContent.first
      @database.sqls
      # reset the columns because it messes up prepared statments in the mock adapter
      @database.columns = nil
    end

    after do
      Object.send :remove_const, :AssocContent rescue nil
    end

    it "load the owner" do
      @database.fetch = { id: 7, type_sid:"AssocContent", parent_id: nil }
      parent = @child.parent
      @database.sqls.must_equal ["SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.id = 7)) LIMIT 1"]
      parent.must_be_instance_of AssocContent
      parent.id.must_equal 7
    end

    it "loads the owner in a revision" do
      @database.fetch = { id: 7, type_sid:"AssocContent", parent_id: nil }
      parent = nil
      @mapper.scope(23, true) do
        parent = @child.parent
      end
      @database.sqls.must_equal ["SELECT * FROM __r00023_content WHERE ((hidden IS FALSE) AND (type_sid IN ('MockContent2', 'MockContent3')) AND (__r00023_content.id = 7)) LIMIT 1"]
      parent.must_be_instance_of AssocContent
      parent.id.must_equal 7
    end

    it "cache the result" do
      parent = @child.parent
      @database.sqls.must_equal ["SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.id = 7)) LIMIT 1"]
      parent = @child.parent
      @database.sqls.must_equal [ ]
    end

    it "reload the result if asked" do
      parent = @child.parent
      @database.sqls.must_equal ["SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.id = 7)) LIMIT 1"]
      parent = @child.parent(reload: true)
      @database.sqls.must_equal ["SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.id = 7)) LIMIT 1"]
    end

    it "allow access to the relation dataset" do
      results = @child.parent_dataset.filter { id > 3 }.first
      @database.sqls.must_equal ["SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.id = 7) AND (id > 3)) LIMIT 1"]
    end

    it "allow setting of owner for instance" do
      instance = AssocContent.new
      @database.sqls
      instance.parent = @child
      instance.parent_id.must_equal 8
      instance.save
      @database.sqls.first.must_equal \
        "INSERT INTO content (parent_id, type_sid) VALUES (8, 'AssocContent')"
    end

    it "set the reciprocal relation" do
      @database.fetch = { id: 7, type_sid:"AssocContent" }
      parent = AssocContent.first
      @database.sqls
      @database.fetch = [
        { id: 8, type_sid:"AssocContent", parent_id: 7 },
        { id: 9, type_sid:"AssocContent", parent_id: 7 }
      ]
      children = parent.children
      children.map { |c| c.parent.object_id }.uniq.must_equal [parent.object_id]
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (content.parent_id = 7))"
      ]
    end

    describe "sequel models" do
      before do
        @database.columns = @columns
        ::Other = Class.new(Sequel::Model(:other)) do ; end
        Other.db = @database
        AssocContent.many_to_one :other, class: Other, key: :parent_id
        @database.fetch = { id: 7, type_sid:"AssocContent", parent_id: 34 }
        @instance = AssocContent.first
        @database.sqls
        Other.any_instance.stubs(:parent_id).returns(7)
        @other = Other.new
        @other.stubs(:id).returns(34)
        @other.stubs(:pk).returns(34)
      end

      after do
        Object.send :remove_const, :Other rescue nil
      end

      it "can load association members" do
        @instance.other
        @database.sqls.must_equal [
          "SELECT * FROM other WHERE (id = 34) LIMIT 1"
        ]
      end

      it "can add new association members" do
        @database.fetch = { id: 7, type_sid:"AssocContent", parent_id: nil }
        instance = AssocContent.first
        instance.other = @other
        instance.parent_id.must_equal 34
      end

      it "can remove association members" do
        @instance.other = nil
        @instance.parent_id.must_be_nil
      end

      it "can access the association dataset" do
        @instance.other_dataset.sql.must_equal "SELECT * FROM other WHERE (other.id = 34) LIMIT 1"
      end

      it "reloads the association" do
        @instance.other
        @instance.reload
        @database.sqls
        @instance.other
        @database.sqls.must_equal [
          "SELECT * FROM other WHERE (id = 34) LIMIT 1"
        ]
      end
    end
  end

  describe "one_to_one associations" do
    before do
      @database.columns = @expected_columns + [:parent_id]
      AssocContent = Spontaneous::DataMapper::Model(:content, @database, @schema)
      ::Other = Class.new(Sequel::Model(:other)) do ; end
      Other.db = @database
      AssocContent.one_to_one :other, class: Other, key: :parent_id
      @database.fetch = { id: 7, type_sid:"AssocContent", parent_id: 34 }
      @instance = AssocContent.first
      @database.sqls
      @other = Other.new
      @other.stubs(:id).returns(34)
      @other.stubs(:pk).returns(34)
    end

    after do
      Object.send :remove_const, :Other rescue nil
      Object.send :remove_const, :AssocContent rescue nil
    end

    it "can load association members" do
      @instance.other
      @database.sqls.must_equal [
        "SELECT * FROM other WHERE (other.parent_id = 7) LIMIT 1"
      ]
    end

    it "can add new association members" do
      # @database.fetch = { id: 7, type_sid:"AssocContent", parent_id: nil }
      # instance = AssocContent.first
      @other.expects(:parent_id=).with(7)
      @instance.other = @other
    end

    it "can remove the association target" do
      @instance.other = nil
      @database.sqls.must_equal [
        "BEGIN",
        "UPDATE other SET parent_id = NULL WHERE (parent_id = 7)",
        "COMMIT"
      ]
    end

    it "can access the association dataset" do
      @instance.other_dataset.sql.must_equal "SELECT * FROM other WHERE (other.parent_id = 7) LIMIT 1"
    end
  end

  describe "scope cache" do
    it "use a cached version within revision blocks" do
      @mapper.revision(20) do
        assert @mapper.active_scope.equal?(@mapper.active_scope), "Dataset it be the same object"
      end
    end

    it "use an identity map within revision scopes" do
      @database.fetch = [
        { id: 7, type_sid:"MockContent", parent_id: 7 }
      ]
      @mapper.editable do
        a = @mapper.first! :id => 7
        b = @mapper.first! :id => 7
        assert a.object_id == b.object_id, "a and b it be the same object"
      end
    end

    it "use an object cache for #get calls" do
      @database.fetch = [
        [{ id: 8, type_sid:"MockContent", parent_id: 7 }],
        [{ id: 9, type_sid:"MockContent", parent_id: 7 }]
      ]
      @mapper.revision(20) do
        a = @mapper.get(8)
        b = @mapper.get(9)
        @database.sqls
        a = @mapper.get(8)
        b = @mapper.get(9)
        @database.sqls.must_equal []
      end
    end

    it "not create new scope if revisions are the same" do
      a = b = nil
      @mapper.revision(20) do
        a = @mapper.active_scope
        @mapper.revision(20) do
          b = @mapper.active_scope
        end
      end
      assert a.object_id == b.object_id, "Mappers it be same object"
    end

    it "not create new scope if visibility are the same" do
      a = b = nil
      @mapper.scope(20, true) do
        a = @mapper.active_scope
        @mapper.visible do
          b = @mapper.active_scope
        end
      end
      assert a.object_id == b.object_id, "Mappers it be same object"
    end

    it "not create new scope if parameters are the same" do
      a = b = nil
      @mapper.scope(20, true) do
        a = @mapper.active_scope
        @mapper.scope(20, true) do
          b = @mapper.active_scope
        end
      end
      assert a.object_id == b.object_id, "Mappers it be same object"
    end

    it "allows for passing any dataset to base a scope on" do
      ds = @database[:something].filter(socks: "green")
      @mapper.with(ds) do
        @mapper.get(23)
      end
      @database.sqls.must_equal [
        "SELECT * FROM something WHERE ((socks = 'green') AND (type_sid IN ('MockContent2', 'MockContent3')) AND (id = 23)) LIMIT 1"
      ]
    end

    it "gives an empty revision & visibility setting for dataset scopes" do
      ds = @database[:something].filter(socks: "green")
      @mapper.scope(23, true) do
        @mapper.with(ds) do
          refute @mapper.visible_only?
          @mapper.current_revision.must_be_nil
        end
      end
    end

    it "allows for separate configuration of revision & visibility" do
      ds = @database[:something].filter(socks: "green")
      @mapper.scope!(23, true, ds) do
        assert @mapper.visible_only?
        @mapper.current_revision.must_equal 23
      end
    end

    it "allow for using a custom cache key" do
      @database.fetch = [
        { id: 20, type_sid:"MockContent", parent_id: 7 }
      ]
      a = b = nil
      @mapper.scope(20, false) do
        a = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
        b = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
      end
      @database.sqls.must_equal [
        "SELECT * FROM __r00020_content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (label = 'frog')) LIMIT 1"
      ]
    end

    it "uses a distinct cache for each scope" do
      @database.fetch = [
        { id: 20, type_sid:"MockContent", parent_id: 7 }
      ]
      a = b = c = nil
      @mapper.scope(20, false) do
        a = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
        @mapper.scope(nil, false) do
          b = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
          @mapper.scope(20, true) do
            c = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
          end
        end
        a = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
      end
      @database.sqls.must_equal [
        "SELECT * FROM __r00020_content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (label = 'frog')) LIMIT 1",
        "SELECT * FROM content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (label = 'frog')) LIMIT 1",
        "SELECT * FROM __r00020_content WHERE ((hidden IS FALSE) AND (type_sid IN ('MockContent2', 'MockContent3')) AND (label = 'frog')) LIMIT 1",
      ]
    end

    it "allows for clearing specific scope cache keys" do
      @database.fetch = [
        { id: 20, type_sid:"MockContent", parent_id: 7 }
      ]
      a = b = nil
      @mapper.scope(20, false) do
        a = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
        @mapper.clear_cache("key")
        b = @mapper.with_cache("key") { @mapper.filter(nil, label: "frog").first }
      end
      @database.sqls.must_equal [
        "SELECT * FROM __r00020_content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (label = 'frog')) LIMIT 1",
        "SELECT * FROM __r00020_content WHERE ((type_sid IN ('MockContent2', 'MockContent3')) AND (label = 'frog')) LIMIT 1"
      ]
    end

    it "allow for forcing the creation of a new scope to bypass the cache" do
      @database.fetch = [
        { id: 7, type_sid:"MockContent", parent_id: 7 }
      ]
      a = b = c = nil

      @mapper.scope(nil, false) do
        a = @mapper.first! :id => 7
        @mapper.scope(nil, false) do
          b = @mapper.first! :id => 7
          @mapper.scope!(nil, false) do
            c = @mapper.first! :id => 7
          end
        end
      end
      assert a.object_id == b.object_id, "a and b it be the same object"
      assert a.object_id != c.object_id
    end

    it "update the instance cache with updated values after a reload" do
      @database.fetch = [
        [{ id: 7, type_sid:"MockContent", parent_id: 7, label: "a" }],
        [{ id: 7, type_sid:"MockContent", parent_id: 7, label: "b" }],
        [{ id: 7, type_sid:"MockContent", parent_id: 7, label: "b" }]
      ]
      a = b = c = nil
      la = lb = lc = nil

      @mapper.scope(nil, false) do
        a = @mapper.first! :id => 7
        la = a.label
        b = a.reload
        lb = b.label
        c = @mapper.get 7
        lc = c.label
      end
      assert [la, lb, lc] == ["a", "b", "b"], "Incorrect labels #{[la, lb, lc].inspect}"
    end
  end
end

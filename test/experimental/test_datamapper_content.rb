# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class DataMapperContentTest < MiniTest::Spec

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

  def setup
    @expected_columns = DB[:content].columns
    @database = ::Sequel.mock(autoid: 1)
    @database.columns = @expected_columns
    @schema = Spontaneous::Schema.new(Dir.pwd, NameMap)
    content_super = Spontaneous::Model(:content, @database, @schema)
    content_class = Class.new(content_super) do
      include Spontaneous::Content
    end
    Object.const_set(:Content, content_class)
  end

  def teardown
    Object.send :remove_const, :Content rescue nil
  end

  context "Content" do
    should "be defined as a top-level constant" do
      ::Content.must_be_instance_of Class
    end

    should "serialize the correct columns" do
      ::Content.serialized_columns.should == [:field_store, :entry_store, :box_store, :serialized_modifications]
    end

    should "search without type filters" do
      @database.sqls # clear sql log
      ::Content.all
      @database.sqls.should == [
        "SELECT * FROM content"
      ]
    end

    should "have a 'Page' superclass definition" do
      ::Content::Page.must_be_instance_of Class
    end

    should "have a 'Piece' superclass definition" do
      ::Content::Piece.must_be_instance_of Class
    end

    should "use the mapper's cache for retrieval of the site root" do
      @database.sqls # clear sql log
      a = b = nil
      ::Content.with_editable do
        a = ::Content.root
        b = ::Content.root
      end
      @database.sqls.should == [
        "SELECT * FROM content WHERE (path = '/') LIMIT 1"
      ]
    end

    should "use the mapper's cache for retrieval of artibary paths" do
      @database.sqls # clear sql log
      a = b = nil
      ::Content.with_editable do
        a = ::Content.path("/this")
        b = ::Content.path("/this")
      end
      @database.sqls.should == [
        "SELECT * FROM content WHERE (path = '/this') LIMIT 1"
      ]
    end

    should "use the mapper's cache for retrieval via UID" do
      @database.sqls # clear sql log
      a = b = nil
      ::Content.with_editable do
        a = ::Content.uid("fish")
        b = ::Content.uid("fish")
      end
      @database.sqls.should == [
        "SELECT * FROM content WHERE (uid = 'fish') LIMIT 1"
      ]
    end

    context "Pages" do
      setup do
        page_class = Class.new(::Content::Page)
        Object.const_set(:Page, page_class)
        Object.const_set(:P1, Class.new(page_class))
        Object.const_set(:P2, Class.new(page_class))
      end

      teardown do
        Object.send :remove_const, :Page rescue nil
        Object.send :remove_const, :P1   rescue nil
        Object.send :remove_const, :P2   rescue nil
      end

      should "include all page classes when searching from Page base class" do
        @database.sqls # clear sql log
        ::Content::Page.all
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('Page', 'P1', 'P2'))"
        ]
      end

      should "limit searches to a single class for all other page types" do
        @database.sqls # clear sql log
        ::Page.all
        ::P1.all
        ::P2.all
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('Page'))",
          "SELECT * FROM content WHERE (type_sid IN ('P1'))",
          "SELECT * FROM content WHERE (type_sid IN ('P2'))"
        ]
      end

      should "keep a reference to their top-level content model" do
        ::Content::Page.content_model.should == ::Content
        ::Page.content_model.should == ::Content
        ::P1.content_model.should == ::Content
        ::P2.content_model.should == ::Content
      end

      should "provide a class method to return all page instances" do
        @database.sqls # clear sql log
        P2.pages
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('Page', 'P1', 'P2'))"
        ]
      end

      should "provide a class method to return the root of the content hierarchy" do
        @database.sqls # clear sql log
        P2.root
        @database.sqls.should == [
          "SELECT * FROM content WHERE (path = '/') LIMIT 1"
        ]
      end

      should "allow for defining an order" do
        @database.sqls # clear sql log
        P2.order("label").all
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('P2')) ORDER BY 'label'"
        ]
      end

      should "allow for limiting the columns selected" do
        @database.sqls # clear sql log
        P2.select("id").all
        @database.sqls.should == [
          "SELECT 'id' FROM content WHERE (type_sid IN ('P2'))"
        ]
      end
    end

    context "Pieces" do
      setup do
        klass = Class.new(::Content::Piece)
        Object.const_set(:Piece, klass)
        Object.const_set(:P1, Class.new(klass))
        Object.const_set(:P2, Class.new(klass))
      end

      teardown do
        Object.send :remove_const, :Piece rescue nil
        Object.send :remove_const, :P1   rescue nil
        Object.send :remove_const, :P2   rescue nil
      end

      should "include all page classes when searching from Page base class" do
        @database.sqls # clear sql log
        ::Content::Piece.all
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('Piece', 'P1', 'P2'))"
        ]
      end

      should "limit searches to a single class for all other page types" do
        @database.sqls # clear sql log
        ::Piece.all
        ::P1.all
        ::P2.all
        @database.sqls.should == [
          "SELECT * FROM content WHERE (type_sid IN ('Piece'))",
          "SELECT * FROM content WHERE (type_sid IN ('P1'))",
          "SELECT * FROM content WHERE (type_sid IN ('P2'))"
        ]
      end

      should "keep a reference to their top-level content model" do
        ::Content::Piece.content_model.should == ::Content
        ::Piece.content_model.should == ::Content
        ::P1.content_model.should == ::Content
        ::P2.content_model.should == ::Content
        p = P2.new
        p.content_model.should == ::Content
      end

    end
  end
end

# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "DataMapperContent" do

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
    root ||= Dir.mktmpdir
    @expected_columns = DB[:content].columns
    @database = ::Sequel.mock(autoid: 1)
    @database.columns = @expected_columns
    @site = Spontaneous::Site.instantiate(root, :test, :back)
    @schema = Spontaneous::Schema.new(@site, Dir.pwd, NameMap)
    content_super = Spontaneous::Model!(:content, @database, @schema)
    content_class = Class.new(content_super)
    page_class    = Class.new(content_class::Page)
    @site.model = content_class
    Object.const_set(:Content, content_class)
    Object.const_set(:Page, page_class)
  end

  after do
    Object.send :remove_const, :Content rescue nil
    Object.send :remove_const, :Page rescue nil
  end

    it  "be defined as a top-level constant" do
      ::Content.must_be_instance_of Class
    end

    it  "serialize the correct columns" do
      ::Content.serialized_columns.must_equal [:field_store, :box_store, :serialized_modifications]
    end

    it "has a dataset that doesnt filter by type" do
      ds = ::Content.dataset
      ds.must_be_instance_of Spontaneous::DataMapper::Dataset
      ds.sql.must_equal "SELECT * FROM content WHERE (type_sid IN ('Page'))"
    end

    it  "search without type filters" do
      @database.sqls # clear sql log
      ::Content.all
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE (type_sid IN ('Page'))"
      ]
    end

    it "allows for retrieval of a single instance by primary key" do
      @database.sqls # clear sql log
      ::Content.primary_key_lookup(23)
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('Page')) AND (id = 23)) LIMIT 1"
      ]
    end

    it  "have a 'Page' superclass definition" do
      ::Content::Page.must_be_instance_of Class
    end

    it  "have a 'Piece' superclass definition" do
      ::Content::Piece.must_be_instance_of Class
    end

    it  "use the mapper's cache for retrieval of the site root" do
      @database.sqls # clear sql log
      a = b = nil
      ::Content.with_editable do
        a = ::Content.root
        b = ::Content.root
      end
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('Page')) AND (path = '/')) LIMIT 1"
      ]
    end

    it  "use the mapper's cache for retrieval of artibary paths" do
      @database.sqls # clear sql log
      a = b = nil
      ::Content.with_editable do
        a = ::Content.path("/this")
        b = ::Content.path("/this")
      end
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('Page')) AND (path = '/this')) LIMIT 1"
      ]
    end

    it  "use the mapper's cache for retrieval via UID" do
      @database.sqls # clear sql log
      a = b = nil
      ::Content.with_editable do
        a = ::Content.uid("fish")
        b = ::Content.uid("fish")
      end
      @database.sqls.must_equal [
        "SELECT * FROM content WHERE ((type_sid IN ('Page')) AND (uid = 'fish')) LIMIT 1"
      ]
    end

    describe "Pages" do
      before do
        Object.const_set(:P1, Class.new(::Page))
        Object.const_set(:P2, Class.new(::Page))
      end

      after do
        Object.send :remove_const, :P1   rescue nil
        Object.send :remove_const, :P2   rescue nil
      end

      it  "include all page classes when searching from Page base class" do
        @database.sqls # clear sql log
        ::Content::Page.all
        @database.sqls.must_equal [
          "SELECT * FROM content WHERE (type_sid IN ('Page', 'P1', 'P2'))"
        ]
      end

      it "has a dataset that filters for pages" do
        ds = ::Content::Page.dataset
        ds.must_be_instance_of Spontaneous::DataMapper::Dataset
        ds.sql.must_equal "SELECT * FROM content WHERE (type_sid IN ('Page', 'P1', 'P2'))"
      end


      it  "limit searches to a single class for all other page types" do
        @database.sqls # clear sql log
        ::Page.all
        ::P1.all
        ::P2.all
        @database.sqls.must_equal [
          "SELECT * FROM content WHERE (type_sid IN ('Page'))",
          "SELECT * FROM content WHERE (type_sid IN ('P1'))",
          "SELECT * FROM content WHERE (type_sid IN ('P2'))"
        ]
      end

      it  "keep a reference to their top-level content model" do
        ::Content::Page.content_model.must_equal ::Content
        ::Page.content_model.must_equal ::Content
        ::P1.content_model.must_equal ::Content
        ::P2.content_model.must_equal ::Content
      end

      it  "provide a class method to return all page instances" do
        @database.sqls # clear sql log
        P2.pages
        @database.sqls.must_equal [
          "SELECT * FROM content WHERE (type_sid IN ('Page', 'P1', 'P2'))"
        ]
      end

      it  "provide a class method to return the root of the content hierarchy" do
        @database.sqls # clear sql log
        P2.root
        @database.sqls.must_equal [
          "SELECT * FROM content WHERE ((type_sid IN ('Page', 'P1', 'P2')) AND (path = '/')) LIMIT 1"
        ]
      end

      it  "allow for defining an order" do
        @database.sqls # clear sql log
        P2.order("label").all
        @database.sqls.must_equal [
          "SELECT * FROM content WHERE (type_sid IN ('P2')) ORDER BY 'label'"
        ]
      end

      it  "allow for limiting the columns selected" do
        @database.sqls # clear sql log
        P2.select("id").all
        @database.sqls.must_equal [
          "SELECT 'id' FROM content WHERE (type_sid IN ('P2'))"
        ]
      end
    end

    describe "Pieces" do
      before do
        klass = Class.new(::Content::Piece)
        Object.const_set(:Piece, klass)
        Object.const_set(:P1, Class.new(klass))
        Object.const_set(:P2, Class.new(klass))
      end

      after do
        Object.send :remove_const, :Piece rescue nil
        Object.send :remove_const, :P1   rescue nil
        Object.send :remove_const, :P2   rescue nil
      end

      it  "include all page classes when searching from Page base class" do
        @database.sqls # clear sql log
        ::Content::Piece.all
        @database.sqls.must_equal [
          "SELECT * FROM content WHERE (type_sid IN ('Piece', 'P1', 'P2'))"
        ]
      end

      it "has a dataset that filters for pieces" do
        ds = ::Content::Piece.dataset
        ds.must_be_instance_of Spontaneous::DataMapper::Dataset
        ds.sql.must_equal "SELECT * FROM content WHERE (type_sid IN ('Piece', 'P1', 'P2'))"
      end

      it  "limit searches to a single class for all other page types" do
        @database.sqls # clear sql log
        ::Piece.all
        ::P1.all
        ::P2.all
        @database.sqls.must_equal [
          "SELECT * FROM content WHERE (type_sid IN ('Piece'))",
          "SELECT * FROM content WHERE (type_sid IN ('P1'))",
          "SELECT * FROM content WHERE (type_sid IN ('P2'))"
        ]
      end

      it  "keep a reference to their top-level content model" do
        ::Content::Piece.content_model.must_equal ::Content
        ::Piece.content_model.must_equal ::Content
        ::P1.content_model.must_equal ::Content
        ::P2.content_model.must_equal ::Content
        p = P2.new
        p.content_model.must_equal ::Content
      end

    end
end

# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class SearchTest < MiniTest::Spec

  # search should be defined by DSL
  # DSL should
  # - Allow naming of index
  # - Allow restricting of the content by hierarchy
  #   - (Including/Excluding) Page & children (>=)
  #   - (Including/Excluding) Children of page (>)
  # - Allow restricting of indexed content by type
  #   - (Including/Excluding) Specific Page types
  #   - (Including/Excluding) Page types & subclasses (>=)
  #   - (Including/Excluding) Subclasses of type (>)
  #
  # Fields should be included in indexes
  # - Default is to add field to all indexes
  # - Should be able to include on a per index basis
  # - Should be able to set the weight factor globally & per-index
  # - Should be able to partition fields into groups so that in search query you can specify that query is in particular group of fields
  #
  # - Indexing is done by page



  # make sure that S::Piece & S::Page are removed from the schema
  def self.startup
    Object.const_set(:P, Class.new(S::Piece))
    Object.send(:remove_const, :P) rescue nil
    S::Schema.reset!
  end

  context "Search" do
    setup do
      S::Schema.reset!
      Content.delete

      @root = Dir.tmpdir
      @site = S::Site.instantiate(@root, nil, nil)

      class ::Piece < S::Piece; end
      class ::Page < S::Page; end
      Page.box :pages

      class ::PageClass1 < ::Page; end
      class ::PageClass2 < ::Page; end
      class ::PageClass3 < ::PageClass1; end
      class ::PageClass4 < ::PageClass2; end
      class ::PageClass5 < ::PageClass3; end
      class ::PageClass6 < ::PageClass5; end

      @all_page_classes = [::Page, ::PageClass1, ::PageClass2, ::PageClass3, ::PageClass4, ::PageClass5, ::PageClass6]

      @root0 = ::Page.create(:uid => "root")
      @page1 = ::PageClass1.create(:slug => "page1", :uid => "page1")
      @root0.pages << @page1
      @page2 = ::PageClass2.create(:slug => "page2", :uid => "page2")
      @root0.pages << @page2
      @page3 = ::PageClass3.create(:slug => "page3", :uid => "page3")
      @root0.pages << @page3
      @page4 = ::PageClass4.create(:slug => "page4", :uid => "page4")
      @root0.pages << @page4
      @page5 = ::PageClass5.create(:slug => "page5", :uid => "page5")
      @root0.pages << @page5
      @page6 = ::PageClass6.create(:slug => "page6", :uid => "page6")
      @root0.pages << @page6

      @page7 = ::PageClass1.create(:slug => "page7", :uid => "page7")
      @page1.pages << @page7
      @page8 = ::PageClass6.create(:slug => "page8", :uid => "page8")
      @page1.pages << @page8

      @page9 = ::PageClass1.create(:slug => "page9", :uid => "page9")
      @page8.pages << @page9
      @page10 = ::PageClass2.create(:slug => "page10", :uid => "page10")
      @page8.pages << @page10
      @page11 = ::PageClass3.create(:slug => "page11", :uid => "page11")
      @page8.pages << @page11
      @page12 = ::PageClass4.create(:slug => "page12", :uid => "page12")
      @page8.pages << @page12

      @all_pages = [@root0, @page1, @page2, @page3, @page4, @page5, @page6, @page7, @page8, @page9, @page10, @page11, @page12]
      @all_pages.each { |page| page.save; page.reload }
    end

    teardown do
      ([:Piece] + @all_page_classes.map { |k| k.name.to_sym }).each { |klass| Object.send(:remove_const, klass) rescue nil } rescue nil
      Content.delete
    end

    context "indexes" do

      should "be retrievable by name" do
        index = S::Site.index :arthur
        S::Site.indexes[:arthur].must_be_instance_of Spontaneous::Search::Index
        S::Site.indexes[:arthur].name.should == :arthur
        S::Site.indexes[:arthur].should == index
      end

      should "default to indexing all content classes" do
        index = S::Site.index :all
        assert_same_elements (@all_page_classes), index.search_types
      end

      should "allow restriction to particular classes" do
        index = S::Site.index :all do
          select_types ::PageClass1, "PageClass2"
        end
        assert_same_elements [::PageClass1, ::PageClass2], index.search_types
      end

      should "allow restriction to a class & its subclasses" do
        index = S::Site.index :all do
          select_types ">= PageClass1"
        end
        assert_same_elements [::PageClass1, ::PageClass3, ::PageClass5, ::PageClass6], index.search_types
      end

      should "allow restriction to a class's subclasses" do
        index = S::Site.index :all do
          select_types "> PageClass1"
        end
        assert_same_elements [::PageClass3, ::PageClass5, ::PageClass6], index.search_types
      end

      should "allow removal of particular classes" do
        index = S::Site.index :all do
          reject_types ::PageClass1, "PageClass2"
        end
        assert_same_elements (@all_page_classes - [PageClass1, PageClass2]), index.search_types
      end

      should "allow removal of a class and its subclasses" do
        index = S::Site.index :all do
          reject_types ">= PageClass1"
        end
        assert_same_elements (@all_page_classes - [::PageClass1, ::PageClass3, ::PageClass5, ::PageClass6]), index.search_types
      end

      should "allow removal of a class's subclasses" do
        index = S::Site.index :all do
          reject_types "> PageClass1"
        end
        assert_same_elements (@all_page_classes - [::PageClass3, ::PageClass5, ::PageClass6]), index.search_types
      end

      should "default to including all content" do
        index = S::Site.index :all
        @all_pages.each do |page|
          index.include?(page).should be_true
        end
      end

      should "allow restriction to a set of specific pages" do
        id = @root0.id
        path = @page8.path
        index = S::Site.index :all do
          select_pages id, "#page11", path
        end

        @all_pages.map{ |page| index.include?(page) }.should ==
          [true,false,false,false,false,false,false,false,true,false,false,true,false]
      end

      should "allow restriction to a page and its children" do
        index = S::Site.index :all do
          select_pages ">= #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should ==
          [false,false,false,false,false,false,false,false,true,true,true,true,true]
      end

      should "allow restriction to a page's children" do
        index = S::Site.index :all do
          select_pages "> #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should ==
          [false,false,false,false,false,false,false,false,false,true,true,true,true]
      end

      should "allow removal of specific pages" do
        index = S::Site.index :all do
          reject_pages "#page8", "/page1"
        end

        @all_pages.map{ |page| index.include?(page) }.should ==
          [true,false,true,true,true,true,true,true,false,true,true,true,true]
      end

      should "allow removal of a page and its children" do
        index = S::Site.index :all do
          reject_pages "/page1", ">= #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should ==
          [true,false,true,true,true,true,true,true,false,false,false,false,false]
      end

      should "allow removal of a page's children" do
        index = S::Site.index :all do
          reject_pages "/page1", "> #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should ==
          [true,false,true,true,true,true,true,true,true,false,false,false,false]
      end

      should "allow multiple, mixed, page restrictions" do
        index = S::Site.index :all do
          select_pages "#page1", "> #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should ==
          [false,true,false,false,false,false,false,false,false,true,true,true,true]
      end

      should "allow combining of class and page restrictions" do
        index = S::Site.index :all do
          reject_types PageClass3, PageClass4
          select_pages "#page1", "> #page8"
          reject_pages "#page10"
        end
        @all_pages.map{ |page| index.include?(page) }.should ==
          [false,true,false,false,false,false,false,false,false,true,false,false,false]
      end
    end

    context "Indexes" do
      should "correctly filter by type"
    end

    context "Fields definitions" do
      setup do
        @index1 = S::Site.index(:one)
        @index2 = S::Site.index(:two)
        @index3 = S::Site.index(:three) do
          select_types PageClass1
        end
      end

      teardown do
      end

      should "be included in all indexes if :index is set to true" do
        prototype_a = PageClass1.field :a, :index => true
        prototype_a.in_index?(@index1).should be_true
        prototype_a.in_index?(@index2).should be_true
        prototype_a.in_index?(@index3).should be_true
      end

      should "be included in indexes referenced by name" do
        prototype_a = PageClass1.field :a, :index => [:one, :two]
        prototype_a.in_index?(@index1).should be_true
        prototype_a.in_index?(@index2).should be_true
        prototype_a.in_index?(@index3).should be_false
      end

      should "be included in indexes referenced as hash" do
        prototype_a = PageClass1.field :a, :index => {:name => :two}
        prototype_a.in_index?(@index1).should be_false
        prototype_a.in_index?(@index2).should be_true
        prototype_a.in_index?(@index3).should be_false
      end

      should "be included in indexes listed in hash" do
        prototype_a = PageClass1.field :a, :index => [{:name => :one}, {:name => :two}]
        prototype_a.in_index?(@index1).should be_true
        prototype_a.in_index?(@index2).should be_true
        prototype_a.in_index?(@index3).should be_false
      end

      should "return the field's schema id as its index name by default" do
        prototype_a = PageClass1.field :a, :index => [{:name => :one}, {:name => :two, :group => :a}]
        prototype_a.index_id(@index1).should == prototype_a.schema_id.to_s
        prototype_a.index_id(@index2).should == :a
      end

      should "produce a field list in a xapian-fu compatible format" do
        a = PageClass1.field :a, :index => [{:name => :one, :weight => :store},
                                            {:name => :two, :group => :a, :weight => 2}]
        b = PageClass2.field :b, :index => :one
        c = ::Piece.field :c, :index => [{:name => :one, :weight => 4}, {:name => :two, :group => :a}]
        d = ::Piece.field :d, :index => :three
        e = ::PageClass1.field :e, :index => :three
        f = ::PageClass2.field :f, :index => :three

        S::Site.indexes[:one].fields.should == {
          a.schema_id.to_s => { :type => String, :store => true, :index => false},
          b.schema_id.to_s => { :type => String, :store => true, :weight => 1, :index => true},
          c.schema_id.to_s => { :type => String, :store => true, :weight => 4, :index => true}
        }

        S::Site.indexes[:two].fields.should == {
          :a => { :type => String, :store => true, :weight => 2, :index => true}
        }

        S::Site.indexes[:three].fields.should == {
          d.schema_id.to_s => { :type => String, :store => true, :weight => 1, :index => true},
          e.schema_id.to_s => { :type => String, :store => true, :weight => 1, :index => true}
        }
      end


      # Inclusion of field in indexes.
      # Default is not to include field
      # By adding the following clause:
      #
      #   field :title, :index => true
      #
      # you include the :title field in all indexes with a search weight of 1. this is equivalent to the following:
      #
      #   field :title, :index => { :name => :*, :weight => 1, :group => nil }
      #
      # If you only want to include this field in a specific index, then you do the following:
      #
      #   field :title, :index => :tags
      #
      # this is equivalent to
      #
      #   field :title, :index => { :name => :tags, :weight => 1, :group => nil }
      #
      # or if you want to include it into more than one index:
      #
      #   field :title, :index => [:tags, :content]
      #
      # this is equivalent to
      #
      #   field :title, :index => [
      #     { :name => :tags, :weight => 1, :group => nil },
      #     { :name => :content, :weight => 1, :group => nil }]
      #
      # Groups:
      #
      # Normally field values are grouped by content types. Indexes are generated from a page by iterating through
      # all it's pieces and creating a single aggregate value for each field of each type found
      #
      # Groups are a way of joining disparate fields from different types into a single, addressable/searchable
      # index
      #
      # weight:
      #
      # weight defines how much priority is given to a field. I.e. if your search term occurs in a field
      # with a high weight value then it will apear higher in the results list than in a page where the
      # term appears in a lower weight field
      #
      # :store   = 0 : store but don't index (makes value available to results lister without loading page from db)
      # :normal  = 1 : default weight
      # :high    = 2 : high weight
      # :higher  = 4 : higher weight
      # :highest = 8 : higest
      #
      # actual weight are powers of 10: 10, 100, 10000, 100000000 (unless this is different from Ferret)
      #
      #
    end
  end
end

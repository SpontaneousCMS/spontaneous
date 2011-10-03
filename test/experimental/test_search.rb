# encoding: UTF-8

require 'test_helper'

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
  # - Should be able to set the boost factor globally & per-index
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
      ([:Piece] + @all_page_classes.map { |k| k.name.to_sym }).each { |klass| Object.send(:remove_const, klass) rescue nil }
      Content.delete
    end

    context "Index definitions" do

      should "be retrievable by name" do
        index = Spontaneous::Index.create :arthur
        Spontaneous::Index[:arthur].must_be_instance_of Spontaneous::Index
        Spontaneous::Index[:arthur].name.should == :arthur
        Spontaneous::Index[:arthur].should == index
      end

      should "default to indexing all content classes" do
        index = Spontaneous::Index.create :all
        assert_same_elements (@all_page_classes), index.search_classes
      end

      should "allow restriction to particular classes" do
        index = Spontaneous::Index.create :all do
          select_classes ::PageClass1, "PageClass2"
        end
        assert_same_elements [::PageClass1, ::PageClass2], index.search_classes
      end

      should "allow restriction to a class & its subclasses" do
        index = Spontaneous::Index.create :all do
          select_classes ">= PageClass1"
        end
        assert_same_elements [::PageClass1, ::PageClass3, ::PageClass5, ::PageClass6], index.search_classes
      end

      should "allow restriction to a class's subclasses" do
        index = Spontaneous::Index.create :all do
          select_classes "> PageClass1"
        end
        assert_same_elements [::PageClass3, ::PageClass5, ::PageClass6], index.search_classes
      end

      should "allow removal of particular classes" do
        index = Spontaneous::Index.create :all do
          reject_classes ::PageClass1, "PageClass2"
        end
        assert_same_elements (@all_page_classes - [PageClass1, PageClass2]), index.search_classes
      end

      should "allow removal of a class and its subclasses" do
        index = Spontaneous::Index.create :all do
          reject_classes ">= PageClass1"
        end
        assert_same_elements (@all_page_classes - [::PageClass1, ::PageClass3, ::PageClass5, ::PageClass6]), index.search_classes
      end

      should "allow removal of a class's subclasses" do
        index = Spontaneous::Index.create :all do
          reject_classes "> PageClass1"
        end
        assert_same_elements (@all_page_classes - [::PageClass3, ::PageClass5, ::PageClass6]), index.search_classes
      end

      should "default to including all content" do
        index = Spontaneous::Index.create :all
        @all_pages.each do |page|
          index.include?(page).should be_true
        end
      end

      should "allow restriction to a set of specific pages" do
        id = @root0.id
        path = @page8.path
        index = Spontaneous::Index.create :all do
          select_pages id, "#page11", path
        end

        @all_pages.map{ |page| index.include?(page) }.should == [true,false,false,false,false,false,false,false,true,false,false,true,false]
      end

      should "allow restriction to a page and its children" do
        index = Spontaneous::Index.create :all do
          select_pages ">= #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should == [false,false,false,false,false,false,false,false,true,true,true,true,true]
      end

      should "allow restriction to a page's children" do
        index = Spontaneous::Index.create :all do
          select_pages "> #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should == [false,false,false,false,false,false,false,false,false,true,true,true,true]
      end

      should "allow removal of specific pages" do
        index = Spontaneous::Index.create :all do
          reject_pages "#page8", "/page1"
        end

        @all_pages.map{ |page| index.include?(page) }.should == [true,false,true,true,true,true,true,true,false,true,true,true,true]
      end

      should "allow removal of a page and its children" do
        index = Spontaneous::Index.create :all do
          reject_pages "/page1", ">= #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should == [true,false,true,true,true,true,true,true,false,false,false,false,false]
      end

      should "allow removal of a page's children" do
        index = Spontaneous::Index.create :all do
          reject_pages "/page1", "> #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should == [true,false,true,true,true,true,true,true,true,false,false,false,false]
      end

      should "allow multiple, mixed, page restrictions" do
        index = Spontaneous::Index.create :all do
          select_pages "#page1", "> #page8"
        end

        @all_pages.map{ |page| index.include?(page) }.should == [false,true,false,false,false,false,false,false,false,true,true,true,true]
      end

      should "allow combining of class and page restrictions" do
        index = Spontaneous::Index.create :all do
          reject_classes PageClass3, PageClass4
          select_pages "#page1", "> #page8"
          reject_pages "#page10"
        end
        @all_pages.map{ |page| index.include?(page) }.should == [false,true,false,false,false,false,false,false,false,true,false,false,false]
      end
    end

    context "Indexes" do
      should "correctly filter by type"
    end
  end
end

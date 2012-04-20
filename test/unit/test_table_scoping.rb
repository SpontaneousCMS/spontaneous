# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class TableScopingTest < MiniTest::Spec

  def setup
    setup_site
  end

  def teardown
    teardown_site
  end

  def ident(ident)
    Spontaneous.database.dataset.quote_identifier(ident)
  end

  context "Tablename scoping" do
    should "correctly change the table name within a scope" do
      Content.dataset.sql.should == "SELECT * FROM #{ident "content"}"
      Content.with_table("new_content_table") do
        Content.dataset.sql.should == "SELECT * FROM #{ident "new_content_table"}"
      end
      Content.dataset.sql.should == "SELECT * FROM #{ident "content"}"
    end

    should "allow the nesting of scopes" do
      Content.dataset.sql.should == "SELECT * FROM #{ident "content"}"
      Content.with_table("content_1") do
        Content.with_table("content_2") do
          Content.dataset.sql.should == "SELECT * FROM #{ident "content_2"}"
        end
        Content.dataset.sql.should == "SELECT * FROM #{ident "content_1"}"
      end
      Content.dataset.sql.should == "SELECT * FROM #{ident "content"}"
    end

    should "preserve single table inheritance" do
      Content.delete
      class NewContentClass < Piece; end

      id = NewContentClass.create.id
      Content.with_table("content") do
        NewContentClass[id].must_be_instance_of(NewContentClass)
        Content.with_table("content_2") do
          # nothing
        end
      end
      NewContentClass[id].must_be_instance_of(NewContentClass)
      TableScopingTest.send(:remove_const, :NewContentClass)
      Content.delete
    end

    should "restore original state if an exception is raised" do
      Content.dataset.sql.should == "SELECT * FROM #{ident "content"}"
      begin
        Content.with_table("new_content_table") do
          Content.dataset.sql.should == "SELECT * FROM #{ident "new_content_table"}"
          raise "havoc"
        end
      rescue; end
      Content.dataset.sql.should == "SELECT * FROM #{ident "content"}"
    end

    should "Be able to handle scoping multiple models at once" do
      Spontaneous::State.plugin :scoped_table_name
      Content.dataset.sql.should == "SELECT * FROM #{ident "content"}"
      Content.with_table("content_1") do
        State.with_table("state_1") do
          Content.dataset.sql.should == "SELECT * FROM #{ident "content_1"}"
          State.dataset.sql.should == "SELECT * FROM #{ident "state_1"}"
        end
      end

      Content.dataset.sql.should == "SELECT * FROM #{ident "content"}"
      State.dataset.sql.should == "SELECT * FROM #{ident "spontaneous_state"}"
    end
  end
end

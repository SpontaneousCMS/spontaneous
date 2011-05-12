# encoding: UTF-8

require 'test_helper'


class SerialisationTest < MiniTest::Spec
  include Spontaneous
  context "Content" do
    setup do
      Content.delete
      class ::SerialisedPage < Page
        field :direction, :title => "Pointing Direction", :comment => "NSEW" do
          def process(value)
            ({
              "N" => "North",
              "S" => "South",
              "E" => "East",
              "W" => "West"
            })[value.upcase]
          end
        end
        field :thumbnail, :image

        inline_style :dancing
        inline_style :sitting
        inline_style :kneeling

        box :insides
      end
      class ::SerialisedPiece < Piece
        title "Type Title"
        field :title, :string
        field :location, :string, :title => "Where", :comment => "Fill in the address"
        field :date, :date
        field :image do
          sizes :thumbnail => { :width => 50 }
        end

        inline_style :freezing
        inline_style :boiling
        box :things, :title => "My Things" do
          allow :SerialisedPage, :styles => [:sitting, :kneeling]
          field :title, :string
        end
      end


      @class_hash = {
        :type => "SerialisedPiece",
        :is_page => false,
        :title => "Type Title",
        :fields => [
          {:name => "title", :type => "Spontaneous.FieldTypes.StringField", :title => "Title",  :comment => "" , :writable=>true},
          {:name => "location", :type => "Spontaneous.FieldTypes.StringField", :title => "Where",  :comment => "Fill in the address" , :writable=>true},
          {:name => "date", :type => "Spontaneous.FieldTypes.DateField", :title => "Date",  :comment => "" , :writable=>true},
          {:name => "image", :type => "Spontaneous.FieldTypes.ImageField", :title => "Image",  :comment => "", :writable=>true}
      ],
        :boxes => [
          {
            :name => "things",
            :id => "things",
            :title => "My Things",
            :writable => true,
            :allowed_types => ["SerialisedPage"],
            :fields => [{:name => "title", :type => "Spontaneous.FieldTypes.StringField", :title => "Title",  :comment => "" , :writable=>true}]
          }
      ]
      }
    end

    teardown do
      Object.send(:remove_const, :SerialisedPiece)
      Object.send(:remove_const, :SerialisedPage)
    end

    context "classes" do
      should "generate a hash for JSON serialisation" do
        SerialisedPiece.to_hash.should == @class_hash
      end
      should "serialise to JSON" do
        SerialisedPiece.to_json.should == @class_hash.to_json
      end
    end

    context "pieces" do
      setup do

        date = Date.today.to_s

        @root = SerialisedPage.new
        @piece1 = SerialisedPiece.new
        @piece2 = SerialisedPiece.new
        @piece3 = SerialisedPiece.new
        @child = SerialisedPage.new(:slug=> "about")
        @root.insides << @piece1
        @root.insides << @piece2
        @piece1.things << @child
        @child.insides << @piece3

        @piece1.things.title = "Things title"
        @root.title = "Home"
        @root.direction = "S"
        @root.thumbnail = "/images/home.jpg"
        @root.uid = "home"


        @piece1.label = "label1"
        @piece1.slot_name = "The Pages"
        @piece1.title = "Piece 1"
        @piece1.location = "Piece 1 Location"
        @piece1.date = date

        @piece2.label = "label2"
        @piece2.slot_name = "The Doors"
        @piece2.title = "Piece 2"
        @piece2.location = "Piece 2 Location"
        @piece2.date = date

        @piece3.title = "Piece 3"
        @piece3.location = "Piece 3 Location"
        @piece3.date = date

        @child.title = "Child Page"
        @child.thumbnail = "/images/thumb.jpg"
        @child.direction = "N"
        @child.uid = "about"

        @root.pieces[0].style = :freezing
        @root.pieces[0].visible = false
        @root.pieces[1].style = :boiling
        @root.pieces[0].pieces[0].style = :sitting

        @child.path.should == "/about"

        [@root, @piece1, @piece2, @piece3, @child].each { |c| c.save }
        @root_hash = {
          :type=>"SerialisedPage",
          :depth=>0,
          :uid=>"home",
          :path=>"/",
          :hidden => false,
          :fields=> [
            {:unprocessed_value=>"Home", :processed_value=>"Home", :name=>"title", :attributes => {}},
            {:unprocessed_value=>"S", :processed_value=>"South", :name=>"direction", :attributes => {}},
            {:unprocessed_value=>"/images/home.jpg", :processed_value=>"/images/home.jpg", :name=>"thumbnail", :attributes => {}}
        ],
          :is_page=>true,
          :slug=>"",
          :id=>@root.id,
          :boxes => [
            {
          :id=>"insides",
          :fields=>[],
          :entries=> [
          { # root.boxes.first.entries.first
          :type=>"SerialisedPiece",
          :label=>"label1",
          :depth=>1,
          :styles=>["freezing", "boiling"],
          :fields=> [
            {:unprocessed_value=>"Piece 1", :processed_value=>"Piece 1", :name=>"title", :attributes => {}},
            {:unprocessed_value=>"Piece 1 Location", :processed_value=>"Piece 1 Location", :name=>"location", :attributes => {}},
            {:unprocessed_value=>date, :processed_value=>date, :name=>"date", :attributes => {}},
            {:unprocessed_value=>"", :processed_value=>"", :name=>"image", :attributes => {}}
        ],
          :style=>"freezing",
          :hidden => true,
          :boxes => [
            {
          :fields => [{:unprocessed_value=>"Things title", :processed_value=>"Things title", :name=>"title", :attributes => {}}], :id => 'things',
          :entries=> [
            { # root.boxes.entries.first.entries.first
          :type=>"SerialisedPage",
          :path=>"/about",
          :depth=>2,
          :styles=>["dancing", "sitting", "kneeling"],
          :fields=> [
            {:unprocessed_value=>"Child Page", :processed_value=>"Child Page", :name=>"title", :attributes => {}},
            {:unprocessed_value=>"N", :processed_value=>"North", :name=>"direction", :attributes => {}},
            {:unprocessed_value=>"/images/thumb.jpg", :processed_value=>"/images/thumb.jpg", :name=>"thumbnail", :attributes => {}}
        ],
          :uid=>"about",
          :style=>"sitting",
          :hidden => false,
          :is_page=>true,
          :slug=>"about",
          :id=>@child.id
        }
        ],
        }
        ],
          :is_page=>false,
          :name=>"The Pages",
          :id=>@piece1.id
        },
          { # ENTRY
          :type=>"SerialisedPiece",
          :label=>"label2",
          :depth=>1,
          :styles=>["freezing", "boiling"],
          :fields=> [
            {:unprocessed_value=>"Piece 2", :processed_value=>"Piece 2", :name=>"title", :attributes => {}},
            {:unprocessed_value=>"Piece 2 Location", :processed_value=>"Piece 2 Location", :name=>"location", :attributes => {}},
            {:unprocessed_value=>date, :processed_value=>date, :name=>"date", :attributes => {}},
            {:unprocessed_value=>"", :processed_value=>"", :name=>"image", :attributes => {}}
        ],
          :style=>"boiling",
          :hidden => false,
          :is_page=>false,
          :name=>"The Doors",
          :id=>@piece2.id,
        :boxes=>[{:entries=>[], :fields=>[{:unprocessed_value=>"", :processed_value=>"", :name=>"title", :attributes => {}}], :id=>"things"}]
        }
        ]
        }
        ]
        }
      end
      should "generate a hash for JSON serialisation" do
        # pp @root.to_hash
        assert_hashes_equal(@root_hash, @root.to_hash)
      end

      should "serialise to JSON" do
        # hard to test this as the serialisation order appears to change
        @root.to_json.should == @root.to_hash.to_json
      end
    end
  end

  context "Publishing" do
    setup do
      @now = Time.now
      Time.stubs(:now).returns(@now)
      Content.delete
      Change.delete
      @page1 = Page.create
      @page2 = Page.create(:slug => "page2")
      @page1 << @page2
      @page2.save
      @c1 = Change.new
      @c1.push(@page1)
      @c1.push(@page2)
      @c1.save
      @c2 = Change.new
      @c2.push(@page1)
      @c2.push(@page2)
      @c2.save
    end

    teardown do
      Content.delete
      Change.delete
    end

    should "serialise outstanding changes" do
      Change.outstanding.to_json.json.should == [
        {
        :pages=> [
          {:path=>"/", :title=>"New Page", :depth => 0, :id=>@page1.id},
          {:path=>"/page2", :title=>"New Page", :depth => 1, :id=>@page2.id}
      ],
        :changes=> [
          {:page_ids=>[@page1.id, @page2.id], :created_at=> @now.to_s, :id=>@c1.id},
          {:page_ids=>[@page1.id, @page2.id], :created_at=> @now.to_s, :id=>@c2.id}
      ] } ]
    end
  end
end

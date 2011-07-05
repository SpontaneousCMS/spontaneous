# encoding: UTF-8

require 'test_helper'


class SerialisationTest < MiniTest::Spec
  include Spontaneous
  context "Content" do
    setup do
      Content.delete
      Spot::Schema.reset!
      class ::Page < Spontaneous::Page
        field :title, :string, :default => "New Page"
      end

      class ::Piece < Spontaneous::Piece
        style :tepid
      end

      class ::SerialisedPage < ::Page
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

        style :dancing
        style :sitting
        style :kneeling

        box :insides
      end

      class ::SerialisedPiece < ::Piece
        title "Type Title"
        field :title, :string
        field :location, :string, :title => "Where", :comment => "Fill in the address"
        field :date, :date
        field :image do
          size :thumbnail, :width => 50
        end

        style :freezing
        style :boiling

        box :things, :title => "My Things" do
          allow :SerialisedPage, :styles => [:sitting, :kneeling]
          field :title, :string
        end
      end


      @dancing_style = SerialisedPage.style_prototypes[:dancing].schema_id
      @sitting_style = SerialisedPage.style_prototypes[:sitting].schema_id
      @kneeling_style = SerialisedPage.style_prototypes[:kneeling].schema_id

      @freezing_style = SerialisedPiece.style_prototypes[:freezing].schema_id
      @boiling_style = SerialisedPiece.style_prototypes[:boiling].schema_id
      @tepid_style = SerialisedPiece.style_prototypes[:tepid].schema_id

      @fp = SerialisedPiece.field_prototypes

      @class_hash = {
        :type => "SerialisedPiece",
        :id => SerialisedPiece.schema_id.to_s,
        :is_page => false,
        :is_alias=>false,
        :title => "Type Title",
        :styles => [
          {:name => 'freezing', :schema_id => @freezing_style.to_s },
          {:name => 'boiling', :schema_id => @boiling_style.to_s },
          {:name => 'tepid', :schema_id => @tepid_style.to_s }
        ],

        :fields => [
          {:name => "title", :schema_id => @fp[:title].schema_id.to_s, :type => "Spontaneous.FieldTypes.StringField", :title => "Title",  :comment => "" , :writable=>true},
          {:name => "location", :schema_id => @fp[:location].schema_id.to_s, :type => "Spontaneous.FieldTypes.StringField", :title => "Where",  :comment => "Fill in the address" , :writable=>true},
          {:name => "date", :schema_id => @fp[:date].schema_id.to_s, :type => "Spontaneous.FieldTypes.DateField", :title => "Date",  :comment => "" , :writable=>true},
          {:name => "image", :schema_id => @fp[:image].schema_id.to_s, :type => "Spontaneous.FieldTypes.ImageField", :title => "Image",  :comment => "", :writable=>true}
      ],
        :boxes => [
          {
            :name => "things",
            :id => SerialisedPiece.boxes[:things].schema_id.to_s,
            :title => "My Things",
            :writable => true,
            :allowed_types => ["SerialisedPage"],
            :fields => [{:name => "title", :schema_id => SerialisedPiece.boxes[:things].field_prototypes[:title].schema_id.to_s, :type => "Spontaneous.FieldTypes.StringField", :title => "Title",  :comment => "" , :writable=>true}]
          }
      ]
      }
    end

    teardown do
      Object.send(:remove_const, :Page)
      Object.send(:remove_const, :Piece)
      Object.send(:remove_const, :SerialisedPiece)
      Object.send(:remove_const, :SerialisedPage)
    end

    context "classes" do
      should "generate a hash for JSON serialisation" do
        # pp SerialisedPiece.to_hash
        # puts "==================="
        # pp @class_hash
        SerialisedPiece.to_hash.should == @class_hash
      end
      should "serialise to JSON" do
        SerialisedPiece.to_json.json.should == @class_hash
      end
      should "include the title field name in the serialisation of page types" do
        SerialisedPage.to_hash[:title_field].should == 'title'
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
        @piece1.title = "Piece 1"
        @piece1.location = "Piece 1 Location"
        @piece1.date = date

        @piece2.label = "label2"
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
        @root.insides.pieces[0].visible = false
        @root.pieces[1].style = :boiling
        @root.pieces[0].pieces[0].style = :sitting

        @child.path.should == "/about"


        [@root, @child, @piece1, @piece2, @piece3].each { |c| c.save; c.reload }


        @root_hash = {
          :type=>"SerialisedPage",
          :type_id=> SerialisedPage.schema_id.to_s,
          :title => @root.page_title,
          :depth=>0,
          :uid=>"home",
          :path=>"/",
          :hidden => false,
          :fields=> [
            {:unprocessed_value=>"Home", :processed_value=>"Home", :id => SerialisedPage.field_prototypes[:title].schema_id.to_s, :name=>"title", :attributes => {}},
            {:unprocessed_value=>"S", :processed_value=>"South", :id => SerialisedPage.field_prototypes[:direction].schema_id.to_s, :name=>"direction", :attributes => {}},
            {:unprocessed_value=>"/images/home.jpg", :processed_value=>"/images/home.jpg", :id => SerialisedPage.field_prototypes[:thumbnail].schema_id.to_s, :name=>"thumbnail", :attributes => {}}
        ],
          :is_page=>true,
          :slug=>"",
          :id=>@root.id,
          :boxes => [
            {
          :id=>@root.insides.schema_id.to_s,
          :name => "insides",
          :fields=>[],
          :entries=> [
          { # root.boxes.first.entries.first
          :type=>"SerialisedPiece",
          :type_id=> SerialisedPiece.schema_id.to_s,
          :label=>"label1",
          :depth=>1,
          :styles=>[@freezing_style.to_s, @boiling_style.to_s, @tepid_style.to_s],
          :fields=> [
            {:unprocessed_value=>"Piece 1", :processed_value=>"Piece 1", :id=>SerialisedPiece.field_prototypes[:title].schema_id.to_s, :name => "title", :attributes => {}},
            {:unprocessed_value=>"Piece 1 Location", :processed_value=>"Piece 1 Location", :id=>SerialisedPiece.field_prototypes[:location].schema_id.to_s, :name => "location", :attributes => {}},
            {:unprocessed_value=>date, :processed_value=>date, :id=>SerialisedPiece.field_prototypes[:date].schema_id.to_s, :name => "date", :attributes => {}},
            {:unprocessed_value=>"", :processed_value=>"", :id=>SerialisedPiece.field_prototypes[:image].schema_id.to_s, :name => "image", :attributes => {}}
        ],
          :style=>@freezing_style.to_s,
          :hidden => true,
          :boxes => [
            {
          :fields => [{:unprocessed_value=>"Things title", :processed_value=>"Things title", :id => SerialisedPiece.boxes[:things].field_prototypes[:title].schema_id.to_s, :name=>"title", :attributes => {}}],
          :id => SerialisedPiece.boxes[:things].schema_id.to_s,
          :name => "things",
          :entries=> [
            { # root.boxes.entries.first.entries.first
          :type=>"SerialisedPage",
          :title => @child.page_title,
          :type_id=> SerialisedPage.schema_id.to_s,
          :path=>"/about",
          :depth=>2,
          :styles=>[@dancing_style.to_s, @sitting_style.to_s, @kneeling_style.to_s],
          :fields=> [
            {:unprocessed_value=>"Child Page", :processed_value=>"Child Page", :id=>SerialisedPage.field_prototypes[:title].schema_id.to_s, :name => 'title', :attributes => {}},
            {:unprocessed_value=>"N", :processed_value=>"North", :id=>SerialisedPage.field_prototypes[:direction].schema_id.to_s, :name => "direction", :attributes => {}},
            {:unprocessed_value=>"/images/thumb.jpg", :processed_value=>"/images/thumb.jpg", :id=>SerialisedPage.field_prototypes[:thumbnail].schema_id.to_s, :name => "thumbnail", :attributes => {}}
        ],
          :uid=>"about",
          :style=>@sitting_style.to_s,
          :hidden => true,
          :is_page=>true,
          :slug=>"about",
          :id=>@child.id
        }
        ],
        }
        ],
          :is_page=>false,
          # :name=>"The Pages",
          :id=>@piece1.id
        },
          { # ENTRY
          :type=>"SerialisedPiece",
          :type_id=> SerialisedPiece.schema_id.to_s,
          :label=>"label2",
          :depth=>1,
          :styles=>[@freezing_style.to_s, @boiling_style.to_s, @tepid_style.to_s],
          :fields=> [
            {:unprocessed_value=>"Piece 2", :processed_value=>"Piece 2", :id => SerialisedPiece.field_prototypes[:title].schema_id.to_s, :name=>"title", :attributes => {}},
            {:unprocessed_value=>"Piece 2 Location", :processed_value=>"Piece 2 Location", :id => SerialisedPiece.field_prototypes[:location].schema_id.to_s, :name=>"location", :attributes => {}},
            {:unprocessed_value=>date, :processed_value=>date, :id => SerialisedPiece.field_prototypes[:date].schema_id.to_s, :name=>"date", :attributes => {}},
            {:unprocessed_value=>"", :processed_value=>"", :id => SerialisedPiece.field_prototypes[:image].schema_id.to_s, :name=>"image", :attributes => {}}
        ],
          :style=>@boiling_style.to_s,
          :hidden => false,
          :is_page=>false,
          # :name=>"The Doors",
          :id=>@piece2.id,
        :boxes=>[{:entries=>[], :fields=>[{:unprocessed_value=>"", :processed_value=>"", :id => @piece2.things.field_prototypes[:title].schema_id.to_s,:name=>"title", :attributes => {}}],
                  :id=>@piece2.things.schema_id.to_s,
                  :name => "things"
        }]
        }
        ]
        }
        ]
        }
        @root = Content[@root.id]
      end

      should "generate a hash for JSON serialisation" do
       # puts; pp @root_hash; pp @root.to_hash
        assert_hashes_equal(@root_hash, @root.to_hash)
      end

      should "serialise to JSON" do
        # hard to test this as the serialisation order appears to change
        @root.to_json.json.should == @root.to_hash
      end
    end
  end

  context "Publishing" do
    setup do
      Spot::Schema.reset!
      class ::Page < Spontaneous::Page
        field :title, :string, :default => "New Page"
      end
      @now = Time.now
      Time.stubs(:now).returns(@now)
      Content.delete
      Change.delete
      @page1 = ::Page.create
      @page2 = ::Page.create(:slug => "page2")
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
      Object.send(:remove_const, :Page)
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

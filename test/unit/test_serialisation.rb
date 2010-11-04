# encoding: UTF-8

require 'test_helper'


class SerialisationTest < Test::Unit::TestCase
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
      end
      class ::SerialisedFacet < Facet
        title "Type Title"
        field :title, :string
        field :location, :string, :title => "Where", :comment => "Fill in the address"
        field :date, :date
        field :image do
          sizes :thumbnail => { :width => 50 }
        end

        inline_style :freezing
        inline_style :boiling
        allow :SerialisedPage, :styles => [:sitting, :kneeling]
      end


      @class_hash = {
        :type => "SerialisedFacet",
        :title => "Type Title",
        :fields => [
          {:name => "title", :type => "Spontaneous.FieldTypes.StringField", :title => "Title",  :comment => "" },
          {:name => "location", :type => "Spontaneous.FieldTypes.StringField", :title => "Where",  :comment => "Fill in the address" },
          {:name => "date", :type => "Spontaneous.FieldTypes.DateField", :title => "Date",  :comment => "" },
          {:name => "image", :type => "Spontaneous.FieldTypes.ImageField", :title => "Image",  :comment => "" }
      ],
        :allowed_types => ["SerialisedPage"] 
      }
    end

    teardown do
      Object.send(:remove_const, :SerialisedFacet)
      Object.send(:remove_const, :SerialisedPage)
    end

    context "classes" do
      should "generate a hash for JSON serialisation" do
        SerialisedFacet.to_hash.should == @class_hash
      end
      should "serialise to JSON" do
        SerialisedFacet.to_json.should == @class_hash.to_json
      end
    end

    context "facets" do
      setup do

        date = Date.today.to_s

        @root = SerialisedPage.new
        @facet1 = SerialisedFacet.new
        @facet2 = SerialisedFacet.new
        @facet3 = SerialisedFacet.new
        @child = SerialisedPage.new(:slug=> "about")
        @root << @facet1
        @root << @facet2
        @facet1 << @child
        @child << @facet3


        @root.title = "Home"
        @root.direction = "S"
        @root.thumbnail = "/images/home.jpg"
        @root.uid = "home"


        @facet1.label = "label1"
        @facet1.slot_name = "The Pages"
        @facet1.title = "Facet 1"
        @facet1.location = "Facet 1 Location"
        @facet1.date = date

        @facet2.label = "label2"
        @facet2.slot_name = "The Doors"
        @facet2.title = "Facet 2"
        @facet2.location = "Facet 2 Location"
        @facet2.date = date

        @facet3.title = "Facet 3"
        @facet3.location = "Facet 3 Location"
        @facet3.date = date

        @child.title = "Child Page"
        @child.thumbnail = "/images/thumb.jpg"
        @child.direction = "N"
        @child.uid = "about"

        @root.entries[0].style = :freezing
        @root.entries[1].style = :boiling
        @root.entries[0].entries[0].style = :sitting

        @child.path.should == "/about"

        [@root, @facet1, @facet2, @facet3, @child].each { |c| c.save }
        @root_hash = {:type=>"SerialisedPage",
          :depth=>0,
          :path=>"/",
          :fields=>
        [{:unprocessed_value=>"Home", :processed_value=>"Home", :name=>"title"},
          {:unprocessed_value=>"S", :processed_value=>"South", :name=>"direction"},
          {:unprocessed_value=>"/images/home.jpg",
            :processed_value=>"/images/home.jpg",
            :name=>"thumbnail"}],
            :uid=>"home",
            :entries=>
        [{:type=>"SerialisedFacet",
          :label=>"label1",
          :depth=>1,
          :styles=>["freezing", "boiling"],
          :fields=>
        [
          {:unprocessed_value=>"Facet 1",
            :processed_value=>"Facet 1",
            :name=>"title"},
          {:unprocessed_value=>"Facet 1 Location",
            :processed_value=>"Facet 1 Location",
            :name=>"location"},
          {:unprocessed_value=>date,
            :processed_value=>date,
            :name=>"date"},
          {:unprocessed_value=>"",
            :processed_value=>"",
            :name=>"image"} ],
                :style=>"freezing",
              :entries=>
        [{:type=>"SerialisedPage",
          :path=>"/about",
          :depth=>2,
          :styles=>["sitting", "kneeling"],
          :fields=>
        [{:unprocessed_value=>"Child Page",
          :processed_value=>"Child Page",
          :name=>"title"},
          {:unprocessed_value=>"N",
            :processed_value=>"North",
            :name=>"direction"},
            {:unprocessed_value=>"/images/thumb.jpg",
              :processed_value=>"/images/thumb.jpg",
              :name=>"thumbnail"}],
              :uid=>"about",
              :style=>"sitting",
              :is_page=>true,
              :slug=>"about",
              :id=>@child.id}],
              :is_page=>false,
              :name=>"The Pages",
              :id=>@facet1.id},
              {:type=>"SerialisedFacet",
                :label=>"label2",
                :depth=>1,
                :styles=>["freezing", "boiling"],
                :fields=>
        [{:unprocessed_value=>"Facet 2",
          :processed_value=>"Facet 2",
          :name=>"title"},
          {:unprocessed_value=>"Facet 2 Location",
            :processed_value=>"Facet 2 Location",
            :name=>"location"},
            {:unprocessed_value=>date,
              :processed_value=>date,
              :name=>"date"},
            {:unprocessed_value=>"",
              :processed_value=>"",
              :name=>"image"} ],
              :style=>"boiling",
              :entries=>[],
              :is_page=>false,
              :name=>"The Doors",
              :id=>@facet2.id}],
              :is_page=>true,
              :slug=>"",
              :id=>@root.id}
      end
      should "generate a hash for JSON serialisation" do
        @root.to_hash.should == @root_hash
      end

      should "serialise to JSON" do
        # hard to test this as the serialisation order appears to change
        @root.to_json.should == @root.to_hash.to_json
      end
    end
  end
end

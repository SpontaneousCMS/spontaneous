# encoding: UTF-8

require 'test_helper'

class AliasTest < Test::Unit::TestCase

  context "Aliases:" do
    setup do
      class ::Animal < Facet
        field :colour
        field :smell
      end
      class ::Monkey < Animal
        field :fleas
      end
      class ::Pig < Monkey
        field :bacon
      end

      class Compound < Page
        field :door
      end
      class Sty < Compound
        field :mud
      end

      class ::AnimalAlias < Facet
        alias_of :Animal

        field :vet
      end
      class ::MonkeyAlias < Facet
        alias_of :Monkey
      end
      class ::PigAlias < Facet
        alias_of :Pig
      end


      class ::StyAlias < Facet
      end
      class ::CompoundAlias < Page
      end
      class ::MultipleAlias < Facet
        alias_of :Monkey, :Compound
      end

      @animal = Animal.create.reload
      @monkey = Monkey.create.reload
      @pig = Pig.create.reload
      @compound = Compound.create.reload
      @sty = Sty.create.reload
    end

    teardown do
      [:Animal, :Monkey, :Pig, :Compound, :Sty, :StyAlias, :CompoundAlias, :MultipleAlias].each do |c|
        Object.send(:remove_class, c)
      end
    end

    context "All aliases" do
      should "provide a list of available instances that includes all subclasses" do
        assert_same_elements AnimalAlias.targets, [@animal, @monkey, @pig]
        assert_same_elements MonkeyAlias.targets, [@monkey, @pig]
        assert_same_elements PigAlias.targets, [@pig]
      end

      should "allow aliasing multiple classes" do
        assert_same_elements MultipleAlias.targets, [@monkey, @pig, @compound, @sty]
      end

      should "have their own fields"
      should "have their own styles"
      should "present their target's fields as their own"
      should "present their target's styles as their own"
      should "reference the aliases fields before the targets"
      should "have access to their target's fields"
      should "have access to their target's styles"
      should "have an independent style setting"
      should "have a back link in the target"
      should "not delete their target when deleted"
      should "be deleted when target deleted"
    end
    context "Facet aliases" do
      should "be allowed to target pages"
      should "not be loadable via their compound path when linked to a page"
    end

    context "Page aliases" do
      should "not be allowed to have facet classes as targets"
      should "be discoverable via their compound path"
      should "render the page when accessed via the path"
      should "have access to their target's page styles"
      should "be able to set the page style seen"
    end
  end
end

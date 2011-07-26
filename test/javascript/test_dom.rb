
require 'test_helper'
require 'test_javascript'

class DomTest < MiniTest::Spec
  include JavascriptTestBase

  def setup
    @page = page
  end

  def parse_selector(selector)
    attrs = @page.x("Spontaneous.Dom.parse_selector(#{selector});")
    Hash[attrs.to_ary]
  end

  def create_tag(tag_name, selector=nil, params="''")
    selector += ', ' if selector
    tag = @page.x("var t = Spontaneous.Dom.#{tag_name}(#{selector} #{params});t[0]")
  end
  context "selector parsing" do
    should "work with ids & classes" do
      attrs = parse_selector("'#the-id.class-1.class-2'")
      attrs['id'].should == 'the-id'
      attrs['class'].should == 'class-1 class-2'
    end
    should "work with just classes" do
      attrs = parse_selector("'.class-1.class-2'")
      attrs['class'].should == 'class-1 class-2'
      attrs.has_key?('id').should be_false
    end
    should "work with just an id" do
      attrs = parse_selector("'#the-id'")
      attrs['id'].should == 'the-id'
      attrs.has_key?('class').should be_false
    end

    should "work with multile classes without initial dot" do
      attrs = parse_selector("'class-1.class-2'")
      attrs['class'].should == 'class-1 class-2'
      attrs.has_key?('id').should be_false
    end
    should "work with single class without initial dots" do
      attrs = parse_selector("'class-1'")
      attrs['class'].should == 'class-1'
      attrs.has_key?('id').should be_false
    end
    should "convert string to id" do
      id = @page.x("Spontaneous.Dom.id('the-thing')")
      id.should == "#the-thing"
    end

    context "with arrays" do
      should "recognise ids" do
        attrs = parse_selector("[Spontaneous.Dom.id('the-id'), 'class-1', 'class-2']")
        attrs['id'].should == 'the-id'
        attrs['class'].should == 'class-1 class-2'
      end
      should "recognise classes with initial dot" do
        attrs = parse_selector("[Spontaneous.Dom.id('the-id'), '.class-1', 'class-2']")
        attrs['id'].should == 'the-id'
        attrs['class'].should == 'class-1 class-2'
      end
      should "recognise joined dot style classes" do
        attrs = parse_selector("[Spontaneous.Dom.id('the-id'), '.class-1.class-2', 'class-3']")
        attrs['id'].should == 'the-id'
        attrs['class'].should == 'class-1 class-2 class-3'
      end
    end
    context "tag creation" do
      should "work with selector strings" do
        tag = create_tag('div', "'#fish.foul'")
        tag['id'].should == 'fish'
        tag['className'].should == 'foul'
      end
      should "work with selector arrays" do
        tag = create_tag('div', "[Spontaneous.Dom.id('the-id'), 'class-1', 'class-2']")
        tag['id'].should == 'the-id'
        tag['className'].should == 'class-1 class-2'
      end
      should "work with selector arrays and params" do
        tag = create_tag('div', "[Spontaneous.Dom.id('the-id'), 'class-1', 'class-2']", "{'style':'display: none'}")
        tag['id'].should == 'the-id'
        tag['className'].should == 'class-1 class-2'
        tag.getAttribute('style').should == 'display: none'
      end
      should "work with just params" do
        tag = create_tag('div', nil, "{'style':'display: none'}")
        tag['id'].should be_nil
        tag.getAttribute('style').should == 'display: none'
      end
    end
  end
end

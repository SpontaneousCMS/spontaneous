require 'test_helper'


class TemplatesTest < Test::Unit::TestCase
  include Spontaneous

  context "erubis templates" do
    setup do
      @path ||= File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/templates/template.html.erb"))
      @template = TemplateTypes::ErubisTemplate.new(@path)
    end

    should "render" do
      klass = Class.new(Object) do
        def title
          "THE TITLE"
        end
      end
      instance = klass.new
      output = @template.render(instance.send(:binding))
      output.should == "<html><title>THE TITLE</title></html>\n"
    end
  end
end

# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class CutaneousTest < MiniTest::Spec
  PUBLISH_TEMPLATE = (<<-TEMPLATE)
Text here {{ preview_tag }}


!{ comment which should be ignored }
Text `problem`
${ "<div>" }
$${ "<div>" }
  %{
  a = {:key => title}
  b = a.map { |k, v| "\#{k}=\#{v}" }
  }
Text \\problem
  ${ b }
Text
TEMPLATE

  VIEW_TEMPLATE = (<<-TEMPLATE)
<title>{{ title }}</title>

!{ comment }
Welome

{% 2.times do |n| %}
  {{ names[n] }}
{% end %}

TEMPLATE

  context "publishing parser" do
    setup do
      @parser = Cutaneous::PublishTokenParser.new(PUBLISH_TEMPLATE)
    end

    should "tokenize a single statement" do
      lexer = Cutaneous::PublishTokenParser.new("%{ a = {:a => \"a\" }}")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.should == [:statement, 'a = {:a => "a" }']
    end

    should "tokenize a single expression" do
      lexer = Cutaneous::PublishTokenParser.new("${ a }")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.should == [:expression, 'a']
    end

    should "tokenize plain text" do
      lexer = Cutaneous::PublishTokenParser.new("Hello there")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.should == [:text, 'Hello there']
    end

    should "tokenize a single comment" do
      lexer = Cutaneous::PublishTokenParser.new("!{ comment }")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.should == [:comment,  ' comment ']
    end

    should "tokenize an escaped expresssion" do
      lexer = Cutaneous::PublishTokenParser.new("\\${ something }")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.should == [:text, '${ something }']
    end

    should "tokenize an escaped statement" do
      lexer = Cutaneous::PublishTokenParser.new("\\%{ something }")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.should == [:text, '%{ something }']
    end

    should "tokenize an escaped comment" do
      lexer = Cutaneous::PublishTokenParser.new("\\!{ something }")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.should == [:text, '!{ something }']
    end

    should "correctly tokenize tags within a comment" do
      lexer = Cutaneous::PublishTokenParser.new("!{ %{ a = true } ${ value } !{ nested comment }}")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.should == [:comment,  ' %{ a = true } ${ value } !{ nested comment }']
    end
    should "correctly tokenize a complex template string" do
      @parser.tokens.map { |token| token[0] }.should == [
        :text,
        :comment,
        :text,
        :expression,
        :text,
        :escaped_expression,
        :text,
        :statement,
        :text,
        :expression,
        :text
      ]
    end

    should "correctly post process the expressions" do
      expressions = @parser.tokens
      expected = [
        [:text, "Text here {{ preview_tag }}\n\n\n"],
        [:comment, " comment which should be ignored "],
        [:text, "Text \\`problem\\`\n"],
        [:expression, %("<div>")],
        [:text, "\n"],
        [:escaped_expression, %("<div>")],
        [:text, "\n"],
        [:statement, "a = {:key => title}\n  b = a.map { |k, v| \"\#{k}=\#{v}\" }"],
        [:text, "Text \\\\problem\n  "],
        [:expression, "b"],
        [:text, "\nText\n"]
      ]
      expressions.each_with_index do |s, i|
        s.should == expected[i]
      end
      expressions.should == expected
    end

    should "correctly generate the template script" do
      expected = [
        %(_buf << %Q`Text here {{ preview_tag }}\n\n\n`),
        %(_buf << %Q`Text \\`problem\\`\n`),
        %(_buf << _decode_params(("<div>"))),
        %(_buf << %Q`\n`),
        %(_buf << escape(_decode_params(("<div>")))),
        %(_buf << %Q`\n`),
        "a = {:key => title}\n  b = a.map { |k, v| \"\#{k}=\#{v}\" }",
        %(_buf << %Q`Text \\\\problem\n  `),
        "_buf << _decode_params((b))",
        %(_buf << %Q`\nText\n`),
      ].join("\n") + "\n"
      script = @parser.script
      script.should == expected
    end
  end

  context "view parser" do
    setup do
    end
    should "tokenize a single statement" do
      parser = Cutaneous::RequestTokenParser.new("{% a = {:a => \"a\" } %}")
      tokens = parser.tokens
      tokens.length.should == 1
      tokens.first[0].should == :statement
      tokens.first[1].should == 'a = {:a => "a" }'
    end

    should "tokenize a single expression" do
      parser = Cutaneous::RequestTokenParser.new("{{ a }}")
      tokens = parser.tokens
      tokens.length.should == 1
      tokens.first[0].should == :expression
      tokens.first[1].should == 'a'
    end

    should "tokenize a single escaped expression" do
      parser = Cutaneous::RequestTokenParser.new("{$ a $}")
      tokens = parser.tokens
      tokens.length.should == 1
      tokens.first[0].should == :escaped_expression
      tokens.first[1].should == 'a'
    end

    should "tokenize plain text" do
      parser = Cutaneous::RequestTokenParser.new("Hello there")
      tokens = parser.tokens
      tokens.length.should == 1
      tokens.first[0].should == :text
      tokens.first[1].should == 'Hello there'
    end

    should "tokenize a single comment" do
      parser = Cutaneous::RequestTokenParser.new("!{ comment }")
      tokens = parser.tokens
      tokens.length.should == 1
      tokens.first[0].should == :comment
      tokens.first[1].should == ' comment '
    end

    should "tokenize a mixed template" do
      parser = Cutaneous::RequestTokenParser.new("{% a = [1,2].map { |x| x } %}!{ comment }{{ a }}")
      tokens = parser.tokens
      tokens.length.should == 3
      tokens[0][0].should == :statement
      tokens[1][0].should == :comment
      tokens[2][0].should == :expression
      tokens[0][1].should == 'a = [1,2].map { |x| x }'
      tokens[1][1].should == ' comment '
      tokens[2][1].should == 'a'
    end
    should "tokenize a mixed publish & view template" do
      parser = Cutaneous::RequestTokenParser.new(PUBLISH_TEMPLATE)
      tokens = parser.tokens
      tokens.length.should == 5
      tokens.map { |t| t[0] }.should == [
        :text,
        :expression,
        :text,
        :comment,
        :text
      ]
      tokens[1][1].should == 'preview_tag'
    end
  end


  context "publish templates" do
    context "from files" do
      setup do
        @tmp = Dir.mktmpdir
        @template_path = File.join(@tmp, "template.html.cut")
        File.open(@template_path, "w") do |file|
          file.write(PUBLISH_TEMPLATE)
        end
      end
      teardown do
        FileUtils.rm_r(@tmp)
      end

      should "just be empty if created empty" do
        template = Cutaneous::PublishTemplate.new
        template.filename.should be_nil
        template.script.should be_nil
      end

      should "convert a string" do
        template = Cutaneous::PublishTemplate.new
        template.convert("!{ comment }${ title }", "/path/to/template.html.cut")
        template.filename.should == "/path/to/template.html.cut"
        context = Cutaneous::PublishContext.new(nil, :html, {:title => "title"})
        template.render(context).should == "title"
      end

      should "parse the file if created with one" do
        template = Cutaneous::PublishTemplate.new(@template_path)
        template.filename.should == @template_path
        template.script.should =~ /^\s*_buf/
        context = Cutaneous::PublishContext.new(nil, :html, {:title => "title"})
        # puts template.render(context)
        template.render(context).should == (<<-HTML)
Text here {{ preview_tag }}


Text `problem`
<div>
<div>
Text \\problem
  key=title
Text
        HTML
      end

      should "reset if given a different string" do
        template = Cutaneous::PublishTemplate.new
        template.convert("${ title }")
        context = Cutaneous::PublishContext.new(nil, :html, {:title => "title"})
        template.render(context).should == "title"
        template.convert("${ title }!")
        template.render(context).should == "title!"
      end
    end
  end
  context "view templates" do
    context "from files" do
      setup do
        @tmp = Dir.mktmpdir
        @template_path = File.join(@tmp, "template.html.cut")
        File.open(@template_path, "w") do |file|
          file.write(VIEW_TEMPLATE)
        end
      end
      teardown do
        FileUtils.rm_r(@tmp)
      end

      should "just be empty if created empty" do
        template = Cutaneous::RequestTemplate.new
        template.filename.should be_nil
        template.script.should be_nil
      end

      should "convert a string" do
        template = Cutaneous::RequestTemplate.new
        template.convert("!{ comment }{{ title }}", "/path/to/template.html.cut")
        template.filename.should == "/path/to/template.html.cut"
        context = Cutaneous::RequestContext.new(nil, :html, {:title => "title"})
        template.render(context).should == "title"
      end

      should "parse the file if created with one" do
        template = Cutaneous::RequestTemplate.new(@template_path)
        template.filename.should == @template_path
        template.script.should =~ /^\s*_buf/
        context = Cutaneous::RequestContext.new(nil, :html, {:title => "title", :names => ["george", "mary"]})
        # puts template.render(context)
        template.render(context).should == (<<-HTML)
<title>title</title>

Welome

  george
  mary
        HTML
      end

      should "reset if given a different string" do
        template = Cutaneous::RequestTemplate.new
        template.convert("{{ title }}")
        context = Cutaneous::RequestContext.new(nil, :html, {:title => "title"})
        template.render(context).should == "title"
        template.convert("{{ title }}!")
        template.render(context).should == "title!"
      end
    end
  end
end

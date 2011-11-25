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

  context "publishing parser" do
    setup do
      @lexer = Cutaneous::PublishTokenParser.new(PUBLISH_TEMPLATE)
    end

    should "tokenize a single statement" do
      lexer = Cutaneous::PublishTokenParser.new("%{ a = {:a => \"a\" }}")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::PublishTokenParser::StatementToken)
      tokens.first.expression.should == 'a = {:a => "a" }'
    end

    should "tokenize a single expression" do
      lexer = Cutaneous::PublishTokenParser.new("${ a }")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::PublishTokenParser::ExpressionToken)
      tokens.first.expression.should == 'a'
    end

    should "tokenize plain text" do
      lexer = Cutaneous::PublishTokenParser.new("Hello there")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::PublishTokenParser::TextToken)
      tokens.first.expression.should == 'Hello there'
    end

    should "tokenize a single comment" do
      lexer = Cutaneous::PublishTokenParser.new("!{ comment }")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::PublishTokenParser::CommentToken)
      tokens.first.expression.should == ' comment '
    end

    should "correctly tokenize a complex template string" do
      @lexer.tokens.map { |token| token.class }.should == [
        Cutaneous::PublishTokenParser::TextToken,
        Cutaneous::PublishTokenParser::CommentToken,
        Cutaneous::PublishTokenParser::TextToken,
        Cutaneous::PublishTokenParser::ExpressionToken,
        Cutaneous::PublishTokenParser::TextToken,
        Cutaneous::PublishTokenParser::EscapedExpressionToken,
        Cutaneous::PublishTokenParser::TextToken,
        Cutaneous::PublishTokenParser::StatementToken,
        Cutaneous::PublishTokenParser::TextToken,
        Cutaneous::PublishTokenParser::ExpressionToken,
        Cutaneous::PublishTokenParser::TextToken
      ]
    end

    should "correctly collect the expressions" do
      expected = [
        "Text here {{ preview_tag }}\n\n\n",
        " comment which should be ignored ",
        "Text `problem`\n",
        " \"<div>\" ",
        "\n",
        " \"<div>\" ",
        "\n",
        "\n  a = {:key => title}\n  b = a.map { |k, v| \"\#{k}=\#{v}\" }\n  ",
        "Text \\problem\n  ",
        " b ",
        "\nText\n"
      ]
      expressions = @lexer.tokens.map { |token| token.raw_expression }
      expressions.each_with_index do |e, i|
        e.should == expected[i]
      end
      expressions.should == expected
    end

    should "correctly post process the expressions" do
      expressions = @lexer.tokens.map { |token| token.expression }
      expected = [
        "Text here {{ preview_tag }}\n\n\n",
        " comment which should be ignored ",
        "Text `problem`\n",
        %("<div>"),
        "\n",
        %("<div>"),
        "\n",
        "a = {:key => title}\n  b = a.map { |k, v| \"\#{k}=\#{v}\" }",
        "Text \\problem\n  ",
        "b",
        "\nText\n"
      ]
      expressions.each_with_index do |s, i|
        s.should == expected[i]
      end
      expressions.should == expected
    end

    should "correctly convert the expressions to template script code" do
      scripts =  @lexer.tokens.map { |token| token.script }

      expected = [
        %(_buf << %Q`Text here {{ preview_tag }}\n\n\n`\n),
        nil,
        %(_buf << %Q`Text \\`problem\\`\n`\n),
        %(_buf << _decode_params(("<div>"))\n),
        %(_buf << %Q`\n`\n),
        %(_buf << escape(_decode_params(("<div>")))\n),
        %(_buf << %Q`\n`\n),
        "a = {:key => title}\n  b = a.map { |k, v| \"\#{k}=\#{v}\" }\n",
        %(_buf << %Q`Text \\\\problem\n  `\n),
        "_buf << _decode_params((b))\n",
        %(_buf << %Q`\nText\n`\n),
      ]
      scripts.each_with_index do |s, i|
        s.should == expected[i]
      end
      scripts.should == expected
    end

    should "correctly generate the template script" do
      expected = %Q/_buf << %Q`Text here {{ preview_tag }}\n\n\n`\n_buf << %Q`Text \\`problem\\`\n`\n_buf << _decode_params(("<div>"))\n_buf << %Q`\n`\n_buf << escape(_decode_params(("<div>")))\n_buf << %Q`\n`\na = {:key => title}\n  b = a.map { |k, v| "\#{k}=\#{v}" }\n_buf << %Q`Text \\\\problem\n  `\n_buf << _decode_params((b))\n_buf << %Q`\nText\n`\n/
      script = @lexer.script
      # puts expected
      # puts "================================"
      # puts script
      # puts "================================"
      script.should == expected
    end
  end

  context "publish templates" do
    setup do
    end
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
end

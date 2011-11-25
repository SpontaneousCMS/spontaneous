# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class CutaneousTest < MiniTest::Spec
  context "publishing lexer" do
    setup do
      @lexer = Cutaneous::TokenParser.new((<<-TEMPLATE))
Text here


!{ comment which should be ignored }
Text `problem`
${ "<div>" }
$${ "<div>" }
  %{
  a = {:key => "value"}
  b = a.map { |k, v| "\#{k}=\#{v}" }
  }
Text \\problem
  ${ b }
Text
      TEMPLATE
    end

    should "tokenize a single statement" do
      lexer = Cutaneous::TokenParser.new("%{ a = {:a => \"a\" }}")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::TokenParser::StatementToken)
      tokens.first.expression.should == 'a = {:a => "a" }'
    end

    should "tokenize a single expression" do
      lexer = Cutaneous::TokenParser.new("${ a }")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::TokenParser::ExpressionToken)
      tokens.first.expression.should == 'a'
    end

    should "tokenize plain text" do
      lexer = Cutaneous::TokenParser.new("Hello there")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::TokenParser::TextToken)
      tokens.first.expression.should == 'Hello there'
    end

    should "tokenize a single comment" do
      lexer = Cutaneous::TokenParser.new("!{ comment }")
      tokens = lexer.tokens
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::TokenParser::CommentToken)
      tokens.first.expression.should == ' comment '
    end

    should "correctly tokenize a complex template string" do
      @lexer.tokens.map { |token| token.class }.should == [
        Cutaneous::TokenParser::TextToken,
        Cutaneous::TokenParser::CommentToken,
        Cutaneous::TokenParser::TextToken,
        Cutaneous::TokenParser::ExpressionToken,
        Cutaneous::TokenParser::TextToken,
        Cutaneous::TokenParser::EscapedExpressionToken,
        Cutaneous::TokenParser::TextToken,
        Cutaneous::TokenParser::StatementToken,
        Cutaneous::TokenParser::TextToken,
        Cutaneous::TokenParser::ExpressionToken,
        Cutaneous::TokenParser::TextToken
      ]
    end

    should "correctly collect the expressions" do
      @lexer.tokens.map { |token| token.raw_expression }.should == [
        "Text here\n\n\n",
        " comment which should be ignored ",
        "\nText `problem`\n",
        " \"<div>\" ",
        "\n",
        " \"<div>\" ",
        "\n  ",
        "\n  a = {:key => \"value\"}\n  b = a.map { |k, v| \"\#{k}=\#{v}\" }\n  ",
        "\nText \\problem\n  ",
        " b ",
        "\nText\n"
      ]
    end

    should "correctly post process the expressions" do
      expressions = @lexer.tokens.map { |token| token.expression }
      expected = [
        "Text here\n\n\n",
        " comment which should be ignored ",
        "\nText `problem`\n",
        %("<div>"),
        "\n",
        %("<div>"),
        "\n  ",
        "a = {:key => \"value\"}\n  b = a.map { |k, v| \"\#{k}=\#{v}\" }",
        "\nText \\problem\n  ",
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
        "Text here\n\n\n",
        nil,
        "\nText \\`problem\\`\n",
        '#{"<div>"}',
        "\n",
        '#{escape(("<div>").to_s)}',
        "\n  ",
        "a = {:key => \"value\"}\n  b = a.map { |k, v| \"\#{k}=\#{v}\" };",
        "\nText \\\\problem\n  ",
        '#{b}',
        "\nText\n"
      ]
      scripts.each_with_index do |s, i|
        s.should == expected[i]
      end
      scripts.should == expected
    end

    should "correctly generate the template script" do
      expected = %Q/ _buf << %Q`Text here\n\n\nText \\`problem\\`\n\#{"<div>"}\n\#{escape(("<div>").to_s)}\n  `;a = {:key => \"value\"}\n  b = a.map { |k, v| "\#{k}=\#{v}" }; _buf << %Q`Text \\\\problem\n  \#{b}\nText\n`;/
      script = @lexer.script
      script.should == expected
    end
  end
end

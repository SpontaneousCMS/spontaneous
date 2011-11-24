# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class CutaneousTest < MiniTest::Spec
  context "lexer" do
    setup do
      @lexer = Cutaneous::Lexer.new((<<-TEMPLATE))
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
      lexer = Cutaneous::Lexer.new("%{ a = {:a => \"a\" }}")
      tokens = lexer.lex
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::Lexer::StatementToken)
      tokens.first.expression.should == 'a = {:a => "a" }'
    end

    should "tokenize a single expression" do
      lexer = Cutaneous::Lexer.new("${ a }")
      tokens = lexer.lex
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::Lexer::ExpressionToken)
      tokens.first.expression.should == 'a'
    end

    should "tokenize plain text" do
      lexer = Cutaneous::Lexer.new("Hello there")
      tokens = lexer.lex
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::Lexer::TextToken)
      tokens.first.expression.should == 'Hello there'
    end

    should "tokenize a single comment" do
      lexer = Cutaneous::Lexer.new("!{ comment }")
      tokens = lexer.lex
      tokens.length.should == 1
      tokens.first.must_be_instance_of(Cutaneous::Lexer::CommentToken)
      tokens.first.expression.should == ' comment '
    end

    should "correctly tokenize a complex template string" do
      @lexer.lex.map { |token| token.class }.should == [
        Cutaneous::Lexer::TextToken,
        Cutaneous::Lexer::CommentToken,
        Cutaneous::Lexer::TextToken,
        Cutaneous::Lexer::ExpressionToken,
        Cutaneous::Lexer::TextToken,
        Cutaneous::Lexer::EscapedExpressionToken,
        Cutaneous::Lexer::TextToken,
        Cutaneous::Lexer::StatementToken,
        Cutaneous::Lexer::TextToken,
        Cutaneous::Lexer::ExpressionToken,
        Cutaneous::Lexer::TextToken
      ]
    end

    should "correctly collect the expressions" do
      @lexer.lex.map { |token| token.raw_expression }.should == [
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
      expressions = @lexer.lex.map { |token| token.expression }
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
      scripts =  @lexer.lex.map { |token| token.script }

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
  end
end

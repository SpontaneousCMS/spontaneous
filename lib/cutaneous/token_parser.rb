module Cutaneous
  class TokenParser


    def self.generate(tag_definitions)
      @parser_class = Class.new(Cutaneous::TokenParser) do
        class_map = {
          :comment => "CommentToken",
          :expression => "ExpressionToken",
          :escaped_expression => "EscapedExpressionToken",
          :statement => "StatementToken"
        }
        tag_definitions.each do |type, tag|
          tag_open, tag_close = tag
          class_name = class_map[type]
          token_base_class = Cutaneous::TokenParser.const_get(class_name)
          token_class = Class.new(token_base_class)
          token_class.define_tag(tag_open, tag_close)
          self.token_classes << token_class
          self.const_set(class_name, token_class)
        end
        # self.const_set("TextToken", TextToken)
      end
      @parser_class
    end

    class Token
      def self.define_tag(open, close)
        @tag_open, @tag_close = open, close
      end

      def self.tag_close
        @tag_close
      end

      def self.tag_open
        @tag_open
      end

      def self.before(raw_expression, following_token_class)
        self.new(raw_expression)
      end

      def self.after(raw_expression, preceding_token_class)
        self.new(raw_expression)
      end

      def self.type
        :token
      end

      attr_reader :raw_expression

      def initialize(raw_expression)
        @raw_expression = raw_expression
      end

      alias_method :expression, :raw_expression
      alias_method :script, :expression

      def tag_close
        self.class.tag_close
      end

      def tag_open
        self.class.tag_open
      end

      def text_token?
        true
      end
    end

    class CommentToken < Token
      def self.type
        :comment
      end

      def script
        nil
      end

      def text_token?
        true
      end
    end

    class TextToken < Token
      def self.type
        :text
      end

      def self.bracket(raw_expression, preceeding_token_class, following_token_class)
        expression = raw_expression
        if preceeding_token_class
          case preceeding_token_class.type
          when :comment, :statement
            expression.gsub!(/\A\s*?[\r\n]+/, '')
          end
        end
        if following_token_class
          case following_token_class.type
          when :comment, :statement
            expression.gsub!(/(\r?\n)[ \t]*\z/, '\1')
          end
        end
        self.new(expression)
      end

      def escape(str)
        str.gsub(/[`\\]/, '\\\\\&')
      end

      def script
        %(_buf << %Q`#{escape(expression)}`\n)
      end
    end

    class ExpressionToken < TextToken
      def self.type
        :expression
      end

      def expression
        @expression ||= raw_expression.strip
      end

      def script
        %(_buf << _decode_params((#{expression}))\n)
      end
    end

    class EscapedExpressionToken < ExpressionToken
      def script
        %(_buf << escape(_decode_params((#{expression})))\n)
      end
    end

    class StatementToken < Token
      def self.type
        :statement
      end

      def expression
        @expression ||= raw_expression.strip
      end

      def script
        expression + "\n"
      end

      def text_token?
        false
      end
    end

    def self.token_classes
      @token_classes ||= []
    end

    def self.tag_start_pattern
      @tag_start_pattern ||= compile_start_pattern
    end

    def self.compile_start_pattern
      tags = token_classes.map { |token_class| Regexp.escape(token_class::tag_open) }
      Regexp.new("(#{ tags.join("|") })")
    end

    def self.token_map
      @token_map ||= Hash[token_classes.map { | token_class | [token_class::tag_open, token_class] }]
    end

    def initialize(template)
      @template = template
    end

    def tokens
      @tokens ||= parse
    end

    def script
      @script ||= compile
    end

    protected

    def parse
      tokens = []
      pos = 0
      previous_token = nil
      while (start = @template.index(self.class.tag_start_pattern, pos))
        text = text_token = nil
        if (start > pos)
          text = @template[pos, start - pos]
        end
        pos = start
        offset = 0
        begin
          offset += 1
        end until (token_class = self.class.token_map[@template[pos, offset]])
        pos += offset
        offset = 0
        opening_braces = 1
        closing_braces = 0

        while opening_braces > closing_braces
          char = @template[pos + offset]
          case char
          when "{"
            opening_braces += 1
          when "}"
            closing_braces += 1
          end
          offset += 1
        end
        code = @template[pos, offset - 1]
        text_token = TextToken.bracket(text, previous_token ? previous_token.class : nil, token_class) if text
        token = token_class.after(code, text_token ? TextToken : nil)
        tokens << text_token if text_token
        tokens << token
        previous_token = token
        pos += offset
      end
      if pos < @template.length
        rest = ((pos > 0) ? @template[pos..-1] : @template)
        tokens << TextToken.bracket(rest, previous_token ? previous_token.class : nil, nil)
      end
      tokens
    end

    def compile
      tokens.map(&:script).join
    end
  end
end

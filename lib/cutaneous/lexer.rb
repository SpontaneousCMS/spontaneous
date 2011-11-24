module Cutaneous
  class Lexer


    class Token
      attr_reader :raw_expression
      def initialize(raw_expression)
        @raw_expression = raw_expression
      end

      alias_method :expression, :raw_expression
      alias_method :script, :expression

      def start_token
        TOKEN_START
      end
    end

    class CommentToken < Token
      TOKEN_START = "!{".freeze
      def script
        nil
      end
    end

    class TextToken < Token
      TOKEN_START = nil

      def escape(str)
        str.gsub(/[`\\]/, '\\\\\&')
      end

      def script
        escape(expression)
      end
    end

    class ExpressionToken < Token
      TOKEN_START = "${".freeze

      def expression
        @expression ||= raw_expression.strip
      end

      def script
        %(\#{#{expression}})
      end
    end

    class EscapedExpressionToken < ExpressionToken
      TOKEN_START = "$${".freeze

      def script
        %(\#{escape((#{expression}).to_s)})
      end
    end

    class StatementToken < Token
      TOKEN_START = "%{".freeze

      def expression
        @expression ||= raw_expression.strip
      end

      def script
        expression + ";"
      end
    end

    def self.compile_start_pattern
      starts = TAG_TOKENS.map { |token_class|
        token_class::TOKEN_START }.join("|").gsub(/(\{|\$)/) { |t| "\\#{t}" }
      Regexp.new("(#{starts})")
    end

    TAG_TOKENS ||= [CommentToken, ExpressionToken, EscapedExpressionToken, StatementToken]
    TAG_START_PATTERN ||= compile_start_pattern
    TOKEN_MAP ||= Hash[TAG_TOKENS.map { | token_class | [token_class::TOKEN_START, token_class] }]


    def initialize(template)
      @template = template
    end


    def lex
      tokens = []
      pos = 0
      while (start = @template.index(TAG_START_PATTERN, pos))
        if (start > pos)
          text = @template[pos, start - pos]
          tokens << TextToken.new(text)
        end
        pos = start
        offset = 0
        begin
          offset += 1
        end until (token_class = TOKEN_MAP[@template[pos, offset]])
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
        token = token_class.new(code)
        tokens << token
        pos += offset
      end
      if pos < @template.length
        rest = ((pos > 0) ? @template[pos..-1] : @template)
        tokens << TextToken.new(rest)
      end
      tokens
    end
  end
end

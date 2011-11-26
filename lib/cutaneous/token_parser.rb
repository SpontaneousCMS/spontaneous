module Cutaneous
  class TokenParser

    def self.generate(tag_definitions)
      Class.new(Cutaneous::TokenParser).tap do |parser_class|
        parser_class.tags = tag_definitions
      end
    end

    class << self
      attr_accessor :tags
    end

    def self.token_classes
      @token_classes ||= []
    end

    def self.tag_start_pattern
      @tag_start_pattern ||= compile_start_pattern
    end

    def self.compile_start_pattern
      openings = self.tags.map { |type, tags| Regexp.escape(tags[0]) }
      Regexp.new("(#{ openings.join("|") })")
    end

    def self.token_map
      @token_map ||= Hash[tags.map { | type, tags | [tags[0], type] }]
    end

    def self.is_dynamic?(text)
      !text.index(tag_start_pattern).nil?
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
      token_map = self.class.token_map
      tag_start_pattern = self.class.tag_start_pattern
      tags = self.class.tags

      while (start = @template.index(tag_start_pattern, pos))
        text = nil
        text = @template[pos, start - pos] if (start > pos)
        pos = start

        tag, token_type = token_map.detect { |tag, type| @template[pos, tag.length] == tag }
        pos += tag.length

        offset = 0
        opening_braces = tag.count(?{)
        closing_braces = 0

        while opening_braces > closing_braces
          case @template[pos + offset]
          when ?{
            opening_braces += 1
          when ?}
            closing_braces += 1
          end
          offset += 1
        end

        tokens << place_text_token(text, previous_token, token_type) if text
        token = create_token(token_type, @template[pos, offset - tags[token_type][1].length])
        tokens << token
        previous_token = token_type
        pos += offset
      end
      if pos < @template.length
        text = ((pos > 0) ? @template[pos..-1] : @template)
        tokens << place_text_token(text, previous_token, nil) if text
      end
      tokens
    end

    def create_token(type, expression)
      case type
      when :expression, :escaped_expression, :statement
        expression.strip!
      end
      [type, expression]
    end

    def place_text_token(expression, preceeding_type, following_type)
      case preceeding_type
      when :comment, :statement
        expression.gsub!(/\A\s*?[\r\n]+/, '')
      end
      case following_type
      when :comment, :statement
        expression.gsub!(/(\r?\n)[ \t]*\z/, '\1')
      end
      [:text, expression]
    end

    def compile
      script = ""
      tokens.map do |type, expression|
        case type
        when :text
          script << %(_buf << %Q`#{escape_text(expression)}`\n)
        when :expression
          script << %(_buf << _decode_params((#{expression}))\n)
        when :escaped_expression
          script << %(_buf << escape(_decode_params((#{expression})))\n)
        when :statement
          script << expression + "\n"
        end
      end
      script
    end

    def escape_text(str)
      str.gsub(/[`\\]/, '\\\\\&')
    end
  end
end

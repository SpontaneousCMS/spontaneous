# encoding: UTF-8

require 'strscan'

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
      tokens            = []
      scanner           = StringScanner.new(@template)
      tag_start_pattern = self.class.tag_start_pattern
      token_map         = self.class.token_map
      tags              = self.class.tags
      braces            = /\{|\}/
      previous_token    = nil
      endtags_length    = Hash[tags.map { |type, tags| [type, tags[1].length ]}]

      while (match = scanner.scan_until(tag_start_pattern))
        tag = scanner.matched
        text = match[0, match.length-tag.length]
        token_type = token_map[tag]
        expression = ""
        brace_count = tag.count(?{)

        while brace_count > 0
          expression << scanner.scan_until(braces)
          brace = scanner.matched
          brace_count += ((123 - brace.ord)+1)
        end
        tokens << place_text_token(text, previous_token, token_type) if text.length > 0
        token = create_token(token_type, expression[0, expression.length-(endtags_length[token_type])])
        tokens << token
        previous_token = token_type
      end
      tokens << place_text_token(scanner.rest, previous_token, nil) unless scanner.eos?
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

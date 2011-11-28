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
      Regexp.new("#{ openings.join("|") }")
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

        begin
          expression << scanner.scan_until(braces)
          brace = scanner.matched
          brace_count += ((123 - brace.ord)+1)
        end while (brace_count > 0)

        tokens << place_text_token(text, previous_token, token_type) if text.length > 0
        token = create_token(token_type, expression[0, expression.length-(endtags_length[token_type])])
        tokens << token
        previous_token = token_type
      end
      tokens << place_text_token(scanner.rest, previous_token, nil) unless scanner.eos?
      tokens
    end

    def create_token(type, expression)
      expression.strip! if type == :expression || type == :escaped_expression || type == :statement
      [type, expression]
    end

    BEGINNING_WHITESPACE ||= /\A\s*?[\r\n]+/
    ENDING_WHITESPACE    ||= /(\r?\n)[ \t]*\z/
    ESCAPE_STRING        ||= /[`\\]/

    def place_text_token(expression, preceeding_type, following_type)
      if preceeding_type == :statement || preceeding_type == :comment
        expression.gsub!(BEGINNING_WHITESPACE, '')
      end
      if following_type == :statement || following_type == :comment
        expression.gsub!(ENDING_WHITESPACE, '\1')
      end
      expression.gsub!(ESCAPE_STRING, '\\\\\&')
      [:text, expression]
    end

    def compile
      script = ""
      tokens.each do |type, expression|
        case type
        when :expression
          script << %{_buf << _decode_params((} << expression << %{))\n}
        when :text
          script << %(_buf << %Q`) << expression << %(`\n)
        when :statement
          script << expression << "\n"
        when :escaped_expression
          script << %{_buf << escape(_decode_params((} << expression << %{)))\n}
        end
      end
      script
    end
  end
end

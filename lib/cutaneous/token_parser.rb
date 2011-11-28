# encoding: UTF-8

require 'strscan'

module Cutaneous
  class TokenParser

    class << self
      attr_accessor :tags
    end

    module ClassMethods
      def generate(tag_definitions)
        parser_class = Class.new(Cutaneous::TokenParser)
        parser_class.tags = tag_definitions
        parser_class
      end

      def is_dynamic?(text)
        !text.index(tag_start_pattern).nil?
      end


      def tag_start_pattern
        @tag_start_pattern ||= compile_start_pattern
      end

      def compile_start_pattern
        openings = self.tags.map { |type, tags| Regexp.escape(tags[0]) }
        Regexp.new("#{ openings.join("|") }")
      end

      # map the set of tags into a hash used by the parse routine that converts an opening tag into a
      # list of: tag type, the number of opening braces in the tag and the length of the closing tag
      def token_map
        @token_map ||= Hash[tags.map { |type, tags| [tags[0], [type, tags[0].count(?{), tags[1].length]] }]
      end
    end

    extend ClassMethods

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

    BRACES ||= /\{|\}/

    def parse
      tokens    = []
      scanner   = StringScanner.new(@template)
      tag_start = self.class.tag_start_pattern
      tags      = self.class.tags
      token_map = self.class.token_map
      previous  = nil

      while (text = scanner.scan_until(tag_start))
        tag = scanner.matched
        type, brace_count, endtag_length = token_map[tag]
        text.slice!(text.length - tag.length, text.length)
        expression = ""

        begin
          expression << scanner.scan_until(BRACES)
          brace = scanner.matched
          brace_count += ((123 - brace.ord)+1)
        end while (brace_count > 0)

        expression.slice!(expression.length - endtag_length, expression.length)

        tokens << place_text_token(text, previous, type) if text.length > 0
        tokens << create_token(type, expression)
        previous = type
      end
      tokens << place_text_token(scanner.rest, previous, nil) unless scanner.eos?
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

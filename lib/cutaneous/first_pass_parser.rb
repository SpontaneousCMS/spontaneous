# encoding: UTF-8

module Cutaneous
  class FirstPassParser < Tenjin::Preprocessor
    include ParserCore

    ## %{ ruby_code }
    STMT_PATTERN = /%\{( |\t|\r?\n)(.*?) *\}(?:[ \t]*\r?\n)?/m

    ##  #{ statement } or ${ statement }
    EXPR_PATTERN = /([\$#])\{(.*?)\}/m

    def stmt_pattern
      STMT_PATTERN
    end

    def expr_pattern
      EXPR_PATTERN
    end

    STATEMENT_OPEN = "%{".freeze

    def statement_open
      STATEMENT_OPEN
    end


    def parse_stmts(input)
      return unless input
      input = input.lstrip
      pos = 0

      while statement_start = input.index(statement_open, pos)
        text = input[pos, statement_start - pos].gsub(/\a\s*(\r?\n)+/, '')
        parse_exprs(text)
        pos =  statement_start + statement_open.length
        offset = 0
        opening_braces = 1
        closing_braces = 0
        while opening_braces > closing_braces
          char = input[pos + offset]
          case char
          when "{"
            opening_braces += 1
          when "}"
            closing_braces += 1
          end
          offset += 1
        end
        code = input[pos, offset - 1].strip
        code << ';' unless code[-1] == ?\n
        code = statement_hook(code)
        add_stmt(code)
        pos += offset
        # strip whitespace from end of statements
        if (index = input.index(/[^\s]/, pos))
          pos += (index - pos)
        end
        # while input[pos] =~ /\\s/
      end
      rest = ((pos > 0) ? input[pos..-1] : input).gsub(/\n+\Z/, "\n")
      parse_exprs(rest) if rest && !rest.empty?
    end
  end
end

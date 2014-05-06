# encoding: UTF-8

require 'kramdown'

module Spontaneous::Field
  class Markdown < Base
    has_editor

    def outputs
      [:html]
    end

    def generate_html(input, site)
      input.to_html
    end

    def preprocess(input, site)
      # convert lines ending with newlines into a <br/>
      # as official Markdown syntax isn't suitable for
      # casual users
      # code taken from:
      # http://github.github.com/github-flavored-markdown/
      output = input.gsub(/^[\w\<][^\n]*\n+/) do |x|
        x =~ /\n{2}/ ? x : (x.strip!; x << "  \n")
      end

      # prevent foo_bar_baz from ending up with an italic word in the middle
      output.gsub!(/(^(?! {4}|\t)\w+_\w+_\w[\w_]*)/) do |x|
        x.gsub('_', '\_') if x.split('').sort.to_s[0..1] == '__'
      end
      Kramdown::Document.new(output)
    end

    self.register(:markdown, :markup, :richtext)
  end
end

require 'spontaneous/output/template/renderer'
require 'spontaneous/output/template/engine'

module Spontaneous::Output
  module Template

    PublishSyntax = Cutaneous::FirstPassSyntax
    RequestSyntax = Cutaneous::SecondPassSyntax


    def extension
      Cutaneous.extension
    end

    def is_dynamic?(template_string)
      RequestSyntax.is_dynamic?(template_string)
    end

    extend self
  end
end

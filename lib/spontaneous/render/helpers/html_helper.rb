# encoding: UTF-8

module Spontaneous::Render::Helpers
  module HTMLHelper
    extend self

    def classes(*args)
      args = args.flatten
      optional = args.extract_options!
      optional.each do |class_name, active|
        args << class_name if active
      end
      return "" if args.empty?
      %(class="#{args.join(" ")}")
    end
  end
end

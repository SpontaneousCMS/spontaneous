# encoding: UTF-8

module Spontaneous::Output::Helpers
  module ClassesHelper
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
    Spontaneous::Output::Helpers.register_helper(self, :html)
  end
end

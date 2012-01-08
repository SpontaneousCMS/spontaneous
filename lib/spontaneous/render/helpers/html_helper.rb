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

    def ie_only(version = nil)
      ie_conditional_comment(version)
    end

    def ie_only_gt(version)
      ie_conditional_comment(version, "gt")
    end

    def ie_only_gte(version)
      ie_conditional_comment(version, "gte")
    end

    def ie_only_lt(version)
      ie_conditional_comment(version, "lt")
    end

    def ie_only_lte(version)
      ie_conditional_comment(version, "lte")
    end

    def ie_only_end
      "<![endif]-->"
    end

    def not_ie
       "<!--[if !IE]> -->"
    end

    def not_ie_end
       "<!-- <![endif]-->"
    end

    def ie_conditional_comment(version = nil, test = nil)
      ie_conditional_comment_start(version, test)
    end

    def ie_conditional_comment_start(version = nil, test = nil)
      ["<!--[if ", test_for_version(version, test), "]>"].join
    end

    def test_for_version(version, test)
      if version.is_a?(Range)
        version = version.to_a
        lower = "(#{test_for_version(version.first, "gte")})"
        upper = "(#{test_for_version(version.last,  "lte")})"
        [lower, upper].join("&")
      else
        [test, "IE", version].compact.join(" ")
      end
    end

  end
end

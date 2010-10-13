
Sequel.extension :inflector

module Spontaneous
  SLASH = "/".freeze
  class << self
    def template_root=(template_root)
      @template_root = template_root
    end

    def template_root
      @template_root ||= File.expand_path(File.join(File.dirname(__FILE__), "../templates"))
    end

    def template_ext
      "erb"
    end
  end
end


require File.expand_path("../spontaneous/content", __FILE__)
require File.expand_path("../spontaneous/field_prototype", __FILE__)
require File.expand_path("../spontaneous/field", __FILE__)
require File.expand_path("../spontaneous/field_types", __FILE__)
require File.expand_path("../spontaneous/field_set", __FILE__)
require File.expand_path("../spontaneous/entry", __FILE__)
require File.expand_path("../spontaneous/page_entry", __FILE__)
require File.expand_path("../spontaneous/entry_set", __FILE__)
require File.expand_path("../spontaneous/page", __FILE__)
require File.expand_path("../spontaneous/facet", __FILE__)
require File.expand_path("../spontaneous/style", __FILE__)
require File.expand_path("../spontaneous/style_set", __FILE__)
require File.expand_path("../spontaneous/template", __FILE__)
require File.expand_path("../spontaneous/template_types/erubis_template", __FILE__)
require File.expand_path("../spontaneous/render_context", __FILE__)
require File.expand_path("../spontaneous/render_format_proxy", __FILE__)

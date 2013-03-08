require 'sprockets'
require 'uglifier'
require 'sass'

module Spontaneous
  module Asset
    autoload :AppCompiler, "spontaneous/asset/app_compiler"
    autoload :Environment, "spontaneous/asset/environment"
  end
end
# module Spontaneous
#   module Sass
#     module Helpers
#       def image_url(asset)
#         ::Sass::Script::String.new "url(" + resolver.image_path(asset.value) + ")"
#       end
#
#       def resolver
#         p options#[:quiet]
#         options[:custom][:resolver]
#       end
#     end
#   end
# end
# module Sass
#   module Script
#     module Functions
#       include Spontaneous::Sass::Helpers
#     end
#   end
# end

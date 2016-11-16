require 'sprockets'
require 'uglifier'
require 'sass'

module Spontaneous
  module Asset
    autoload :AppCompiler, "spontaneous/asset/app_compiler"
    autoload :Compiler,    "spontaneous/asset/compiler"
    autoload :Directory,   "spontaneous/asset/directory"
    autoload :Manifest,    "spontaneous/asset/manifest"
    autoload :Manifests,   "spontaneous/asset/manifests"
    autoload :TagHelper,   "spontaneous/asset/tag_helper"
  end
end

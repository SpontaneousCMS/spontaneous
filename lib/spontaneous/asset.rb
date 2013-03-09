require 'sprockets'
require 'uglifier'
require 'sass'

module Spontaneous
  module Asset
    autoload :AppCompiler, "spontaneous/asset/app_compiler"
    autoload :Environment, "spontaneous/asset/environment"
  end
end

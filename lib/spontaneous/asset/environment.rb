require 'sprockets'
require 'uri'

module Spontaneous::Asset
  module Environment
    autoload :Preview, 'spontaneous/asset/environment/preview'
    autoload :Publish, 'spontaneous/asset/environment/publish'

    def self.new(transaction)
      if transaction.publishing?
        publishing(transaction.site, transaction.revision, transaction.development?)
      else
        preview(transaction.site)
      end
    end

    def self.publishing(site, revision, development)
      Publish.new(site, revision, development)
    end

    def self.preview(site = Spontaneous::Site.instance)
      Preview.new(site)
    end

    # takes a path that has optional hash & query parts and splits
    # out the real asset path.
    def self.split_asset_path(path)
      uri = URI(path)
      [uri.path, uri.query, uri.fragment]
    end


    # takes a path that has optional hash & query parts and splits
    # out the real asset path.
    def self.join_asset_path(path, query, hash)
      joined = path.dup
      joined << "?#{query}" if query
      joined << "##{hash}"  if hash
      joined
    end

    module SassFunctions
      def asset_data_uri(path)
        uri = sprockets_context.asset_data_uri(path.value)
        Sass::Script::String.new("url(#{uri})")
      end
    end

    ::Sass::Script::Functions.send :include, SassFunctions

    module RailsCompatibilityShim
      # actually more a sprockets-less compatibility shim
      def compute_public_path(path, root = nil)
        asset_path(path)
      end

      def asset_paths
        self
      end
    end
  end
end

# encoding: UTF-8

require 'simultaneous'
require 'sass'

module Spontaneous::Publishing
  class Immediate
    include ::Simultaneous::Task

    attr_reader :revision

    def initialize(site, revision, steps)
      @site, @revision, @steps = site, revision, steps
    end

    def publish_pages(pages, user = nil)
      publish.publish_pages(pages, user)
    end

    def publish_all(user = nil)
      publish.publish_all(user)
    end

    def publish
      Publish.new(@site, @revision, @steps)
    end

    def rerender
      Rerender.new(@site, @revision, @steps).rerender
    end

    def reindex
      Reindex.new(@site, @revision, @steps).reindex
    end
  end
end

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

    def publish_pages(pages)
      publish.publish_pages(pages)
    end

    def publish_all
      publish.publish_all
    end

    def publish
      Publish.new(@site, @revision, @steps)
    end

    def rerender_revision
      logger.info {  "Re-rendering revision #{@revision}"}
      render_revision
    end
  end
end

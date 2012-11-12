# encoding: UTF-8

module Spontaneous
  module Content
    extend Spontaneous::Concern

    module ClassMethods
      def page?
        false
      end

      def is_page?
        page?
      end

      # terminate the supertype chain here
      def supertype
        nil
      end

      def supertype?
       !supertype.nil?
      end

      def root
        content_model::Page.root
      end

      def log_sql(io = $stdout)
        mapper.logger = ::Logger.new(io)
        yield if block_given?
      ensure
        mapper.logger = nil
      end
    end


    include Enumerable

    include Plugins::SchemaId
    include Plugins::Entry
    include Plugins::Boxes
    include Plugins::Fields
    include Plugins::Entries
    include Plugins::Styles
    include Plugins::SchemaTitle
    include Plugins::Render
    include Plugins::InstanceCode
    include Plugins::Serialisation
    include Plugins::Media
    include Plugins::Publishing
    include Plugins::Modifications
    include Plugins::Aliases
    include Plugins::Visibility
    include Plugins::Prototypes
    include Plugins::Permissions
    include Plugins::ContentGroups
    include Plugins::SchemaHierarchy

    # marker method enabling a simple test for "cms content" vs "everything else"
    def spontaneous_content?
      true
    end

    def alias?
      false
    end

    def root
      content_model::Page.root
    end

    # Provides consistency between aliases & non-aliases
    # so that a mixed list of both can be treated the same
    # (for instance when ensuring uniqueness)
    def target
      self
    end

    def page?
      false
    end

    alias_method :is_page?, :page?

    def start_inline_edit_marker
      "spontaneous:previewedit:start:content id:#{id}"
    end

    def end_inline_edit_marker
      "spontaneous:previewedit:end:content id:#{id}"
    end

    def to_s
      %(#<#{self.class.name} id=#{id}>)
    end

    def each
      iterable.each do |i|
        yield i if block_given?
      end
    end

    def formats
      return page.formats if page
      [:html]
    end

    def log_sql(io = $stdout)
      mapper.logger = ::Logger.new(io)
      yield if block_given?
    ensure
      mapper.logger = nil
    end
  end
end

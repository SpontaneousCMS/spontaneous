# encoding: UTF-8

module Spontaneous
  class Change < Sequel::Model(:changes)
    class << self
      alias_method :sequel_plugin, :plugin
    end

    sequel_plugin :yajl_serialization, :modified_list

    @@instance = nil

    class << self
      def record(&block)
        entry_point = @@instance.nil?
        @@instance ||= self.new(:modified_list => [])
        yield if block_given?
        @@instance.save if entry_point
      ensure
        @@instance = nil if entry_point
      end

      def push(page)
        if @@instance
          @@instance.modified_list << page.id
        end
      end
    end

    def before_update
      self.modified_list.uniq!
    end

    def modified
      @modified ||= modified_list.map { |id| Content[id] }
    end
  end
end

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
      ensure
        if entry_point and !@@instance.modified_list.empty?
          @@instance.save
        end
        @@instance = nil if entry_point
      end

      def recording?
        !@@instance.nil?
      end

      def push(page)
        if @@instance
          @@instance.modified_list << page.id
        end
      end

      def publish_sets
        grouped_changes = self.all.map { |c| [c] }
        begin
          modified = false
          grouped_changes.each_with_index do |inner, i|
            inner_ids = inner.map { |c| c.modified_list }.flatten
            grouped_changes[(i+1)..-1].each_with_index do |outer, j|
              outer_ids = outer.map { |c| c.modified_list }.flatten
              if !(inner_ids & outer_ids).empty?
                modified = true
                grouped_changes.delete(outer)
                grouped_changes[i] += outer
              end
            end
          end
        end while modified

        grouped_changes
      end
    end

    def before_update
      self.modified_list.uniq!
    end

    def modified
      @modified ||= modified_list.map { |id| Content[id] }
    end

    def &(change)
      self.modified_list & change.modified_list
    end
  end
end
